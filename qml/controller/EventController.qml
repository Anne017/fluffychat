import QtQuick 2.4
import Ubuntu.Components 1.3


/* =============================== EVENT CONTROLLER ===============================

The event controller is responsible for handling all events and stay connected
with the matrix homeserver via a long polling http request
*/
Item {

    signal chatListUpdated
    signal chatStateEvent ( var chat, var event )
    signal chatTimelineEvent ( var chat, var event )
    signal chatNotificationEvent ( var chat, var event )

    property var syncRequest: null
    property var since: ""
    property var initialized: false

    function init () {
        storage.getConfig("next_batch", function( res ) {
            since = res
            initialized = true
            if ( since != null ) return sync ()
            matrix.get ("/client/r0/sync", null,function ( response ) {
                if ( waitingForSync ) progressBarRequests--
                matrix.onlineStatus = true
                handleEvents ( response )
                sync ()
            }, null, null, longPollingTimeout )
        })
    }

    function sync () {
        if (matrix.token === null || matrix.token === undefined) return
        var timeout = defaultTimeout
        if ( matrix.onlineStatus ) timeout = longPollingTimeout
        syncRequest = matrix.get ("/client/r0/sync", { "since": since, "timeout": timeout }, function ( response ) {
            if ( waitingForSync ) progressBarRequests--
            if ( matrix.token ) {
                matrix.onlineStatus = true
                handleEvents ( response )
                sync ()
            }
        }, function ( error ) {
            if ( matrix.token ) {
                matrix.onlineStatus = false
                console.log ( "You are offline!! Try to reconnect in a few seconds!" )
                if ( error.errcode === "M_INVALID" ) {
                    mainStack.clear ()
                    mainStack.push(Qt.resolvedUrl("../pages/LoginPage.qml"))
                }
                else {
                    if ( matrix.onlineStatus ) return
                    function Timer() {
                        return Qt.createQmlObject("import QtQuick 2.0; Timer {}", root);
                    }
                    var timer = new Timer();
                    timer.interval = defaultTimeout;
                    timer.repeat = false;
                    timer.triggered.connect(sync)
                    timer.start();
                }
            }
        });
    }


    function restartSync () {
        syncRequest.abort ()
    }


    function waitForSync () {
        if ( waitingForSync ) return
        waitingForSync = true
        progressBarRequests++
    }


    function stopWaitForSync () {
        if ( !waitingForSync ) return
        waitingForSync = false
        progressBarRequests--
    }


    function handleEvents ( response ) {
        //console.log ( "===============New events========", JSON.stringify ( response ) )
        since = response.next_batch
        storage.setConfig ( "next_batch", since )
        var changed = false
        try {
            handleRooms ( response.rooms.join, "join" )
            handleRooms ( response.rooms.leave, "leave" )
            handleRooms ( response.rooms.invite, "invite" )
        }
        catch ( e ) { console.log ( e ) }
        chatListUpdated ()
    }


    function handleRooms ( rooms, membership ) {
        for ( var id in rooms ) {
            var room = rooms[id]

            storage.query ("INSERT OR REPLACE INTO Rooms VALUES(?, ?, COALESCE((SELECT topic FROM Rooms WHERE id='" + id + "'), ''), ?, ?, ?, COALESCE((SELECT prev_batch FROM Rooms WHERE id='" + id + "'), ''))",
            [id,
            membership,
            (room.unead_notifications ? room.unread_notifications.highlight_count : 0),
            (room.unead_notifications ? room.unread_notifications.notification_count : 0),
            (room.timeline ? (room.timeline.limited ? 1 : 0) : 0)])
            if ( room.state ) handleJoinedStateRoomEvents ( id, room.state.events )
            if ( room.timeline ) handleJoinedRoomTimelineEvents ( id, room.timeline.events )
        }
    }


    function handleJoinedStateRoomEvents ( roomid, events ) {
        for ( var i = 0; i < events.length; i++ ) {
            var event = events[i]
            handleStateChanges (roomid, event )
            chatStateEvent ( roomid, event )
        }
    }


    function handleJoinedRoomTimelineEvents ( roomid, events, withSignals ) {
        if ( withSignals == null ) withSignals = true
        for ( var i = 0; i < events.length; i++ ) {
            var event = events[i]
            storage.query ( "INSERT OR IGNORE INTO Roomevents VALUES(?, ?, ?, ?, ?, ?, ?, ?)",
            [ event.event_id, roomid, event.origin_server_ts, event.sender, event.content.body || null, event.content.msgtype || null, event.type, JSON.stringify(event.content) ])
            // Someone changed the topic of a chat
            if ( withSignals ) {
                handleStateChanges (roomid, event )
                if ( roomid === activeChat ) chatTimelineEvent ( roomid, event )
                else chatNotificationEvent ( roomid, event )
            }
        }
    }

    function handleStateChanges ( roomid, event ) {
        if ( event.type === "m.room.name" ) {
            storage.query( "UPDATE Rooms SET topic=? WHERE id=?", [ event.content.name, roomid ])
        }
        if ( event.type === "m.room.member") {
            storage.query( "INSERT OR REPLACE INTO Roommembers VALUES(?, ?, ?, ?, ?)",
            [ roomid, event.sender, event.content.membership, event.content.displayname, event.content.avatar_url ])
        }
    }
}
