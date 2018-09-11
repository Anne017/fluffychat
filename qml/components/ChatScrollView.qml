import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import "../components"

ListView {

    id: chatScrollView

    // If this property is not 1, then the user is not in the chat, but is reading the history
    property var historyCount: 30
    property var requesting: false
    property var initialized: -1
    property var count: model.count
    property var unread: ""
    property var lastEventId: ""

    function update ( sync ) {
        storage.transaction ( "SELECT events.id, events.type, events.content_json, events.content_body, events.origin_server_ts, events.sender, events.status, "+
        " members.matrix_id, members.displayname, members.avatar_url " +
        " FROM Events events, Users members " +
        " WHERE events.chat_id='" + activeChat +
        "' AND members.matrix_id=events.sender " +
        " ORDER BY events.origin_server_ts DESC"
        , function (res) {
            // We now write the rooms in the column
            pushclient.clearPersistent ( activeChatDisplayName )

            model.clear ()
            initialized = res.rows.length
            for ( var i = res.rows.length-1; i >= 0; i-- ) {
                var event = res.rows.item(i)
                event.content = JSON.parse( event.content_json )
                addEventToList ( event )
                if ( event.matrix_id === null ) requestRoomMember ( event.sender )
            }

            // Scroll to last read event
            if ( unread !== "" ) {
                for ( var j = 0; j < count; j++ ) {
                    if ( model.get ( j ).event.id === unread ) {
                        currentIndex = j
                        break
                    }
                }
            }
        })
    }


    function requestRoomMember ( matrixid ) {
        var localActiveChat = activeChat
        matrix.get("/client/r0/rooms/%1/state/m.room.member/%3".arg(activeChat).arg(matrixid), null, function ( res ) {

            // Save the new roommember event in the database
            storage.query( "INSERT OR REPLACE INTO Users VALUES(?, ?, ?, ?, ?)",
            [ localActiveChat,
            matrixid,
            res.membership,
            res.displayname,
            res.avatar_url ])

            // Update the current view
            for ( var i = 0; i < model.count; i++ ) {
                var elem = model.get(i)
                if ( elem.event.sender === matrixid ) {
                    var tempEvent = elem.event
                    tempEvent.matrix_id = matrixid
                    tempEvent.displayname = res.displayname
                    tempEvent.avatar_url = res.avatar_url
                    var tempEvent = elem.event
                    model.set ( j, { "event": tempEvent } )
                }
            }
        } )
    }


    function requestHistory () {
        if ( initialized !== model.count || requesting || (model.count > 0 && model.get( model.count -1 ).event.type === "m.room.create") ) return
        toast.show ( i18n.tr( "Get more messages from the server ...") )
        requesting = true
        var storageController = storage
        storage.transaction ( "SELECT prev_batch FROM Chats WHERE id='" + activeChat + "'", function (rs) {
            if ( rs.rows.length === 0 ) return
            var data = {
                from: rs.rows[0].prev_batch,
                dir: "b",
                limit: historyCount
            }
            matrix.get( "/client/r0/rooms/" + activeChat + "/messages", data, function ( result ) {
                if ( result.chunk.length > 0 ) {
                    storageController.db.transaction(
                        function(tx) {
                            events.transaction = tx
                            events.handleRoomEvents ( activeChat, result.chunk, "history" )
                            update ()
                            requesting = false
                        }
                    )
                    storageController.transaction ( "UPDATE Chats SET prev_batch='" + result.end + "' WHERE id='" + activeChat + "'", function () {
                    })
                }
                else requesting = false
            }, function () { requesting = false } )
        } )
    }


    // This function writes the event in the chat. The event MUST have the format
    // of a database entry, described in the storage controller
    function addEventToList ( event ) {header


        // If the previous message has the same sender and is a normal message
        // then it is not necessary to show the user avatar again
        event.sameSender = model.count > 0 &&
        model.get(0).event.type === "m.room.message" &&
        model.get(0).event.sender === event.sender

        model.insert ( 0, { "event": event } )
        lastEventId = event.id
    }


    // This function handles new events, based on the signal from the event
    // controller. It just has to format the event to the database format
    function handleNewEvent ( sync ) {
        update ()
    }


    ActionSelectionPopover {
        id: contextualActions
        property var contextEvent
        z: 10
        actions: ActionList {
            Action {
                text: i18n.tr("Copy text")
                onTriggered: {
                    mimeData.text = contextualActions.contextEvent.content.body
                    Clipboard.push( mimeData )
                    toast.show( i18n.tr("Text has been copied to the clipboard") )
                }
            }
            Action {
                text: i18n.tr("Cancel")
                onTriggered: contextualActions.hide ()
            }
        }
    }

    MimeData {
        id: mimeData
        text: ""
    }


    width: parent.width
    height: parent.height - 2 * chatInput.height
    anchors.bottom: chatInput.top
    verticalLayoutDirection: ListView.BottomToTop
    delegate: ChatEvent {}
    model: ListModel { id: model }
    onContentYChanged: if ( atYBeginning ) requestHistory ()
}
