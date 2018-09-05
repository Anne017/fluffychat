import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import QtGraphicalEffects 1.0
import "../components"

ListItem {
    id: chatListItem

    property var timeorder: 0
    property var previousMessage: ""

    visible: { searching ? layout.title.text.toUpperCase().indexOf( searchField.displayText.toUpperCase() ) !== -1 : true }
    height: visible ? layout.height : 0

    onClicked: {
        searching = false
        searchField.text = ""
        mainStack.toStart ()
        activeChat = room.id
        activeChatTypingUsers = room.typing || []
        mainStack.push (Qt.resolvedUrl("../pages/ChatPage.qml"))
        if ( room.notification_count > 0 ) matrix.post( "/client/r0/rooms/" + activeChat + "/receipt/m.read/" + room.eventsid, null )
    }

    ListItemLayout {
        id: layout
        width: parent.width - notificationBubble.width - highlightBubble.width
        title.text: i18n.tr("Unknown chat")
        title.font.bold: true
        title.font.italic: room.membership === "invite"
        title.color: settings.darkmode ? "#FFFFFF" : "#000000"
        subtitle.text: i18n.tr("No previous messages")

        Avatar {
            id: avatar
            SlotsLayout.position: SlotsLayout.Leading
            name: room.topic || room.id
            mxc: room.avatar_url || ""
        }

        Component.onCompleted: {

            // Get the last message
            if ( room.membership === "invite" ) {
                layout.subtitle.text = i18n.tr("You have been invited to this chat")
            }
            else if ( room.topic !== "" && room.typing && room.typing.length > 0 ) {
                layout.subtitle.text = usernames.getTypingDisplayString ( room.typing, room.topic )
            }
            else if ( room.content_body ){
                var lastMessage = room.content_body
                if ( room.sender === matrix.matrixid ) lastMessage = i18n.tr("You: ") + lastMessage
                layout.subtitle.text = lastMessage
            }
            else if ( room.content_json ) {
                layout.subtitle.text = displayEvents.getDisplay ( room )
            }
            previousMessage = layout.subtitle.text

            // Get the room name
            if ( room.topic !== "" ) layout.title.text = room.topic
            else roomnames.getById ( room.id, function (displayname) {
                layout.title.text = displayname
                avatar.name = displayname
                // Is there a typing notification?
                if ( room.typing && room.typing.length > 0 ) {
                    layout.subtitle.text = usernames.getTypingDisplayString ( room.typing, displayname )
                }
            })

            // Get the room avatar if single chat
            if ( avatar.mxc === "") roomnames.getAvatarFromSingleChat ( room.id, function ( avatar_url ) {
                avatar.mxc = avatar_url
            } )
        }
    }


    Label {
        id: stampLabel
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: units.gu(2)
        text: stamp.getChatTime ( room.origin_server_ts )
        textSize: Label.XSmall
        visible: text != ""
    }


    // Notification count bubble on the bottom right
    Rectangle {
        id: notificationBubble
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: units.gu(2)
        width: unreadLabel.width + units.gu(1)
        height: units.gu(2)
        color: settings.mainColor
        radius: units.gu(0.5)
        Label {
            id: unreadLabel
            anchors.centerIn: parent
            text: room.notification_count || "0"
            textSize: Label.Small
            color: UbuntuColors.porcelain
        }
        visible: unreadLabel.text != "0"
    }


    Icon {
        id: highlightBubble
        visible: room.highlight_count > 0
        name: "dialog-warning-symbolic"
        anchors.right: notificationBubble.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(2)
        anchors.rightMargin: units.gu(0.5)
        width: units.gu(2)
        height: width
    }


    // Delete Button
    leadingActions: ListItemActions {
        actions: [
        Action {
            iconName: "info"
            onTriggered: {
                activeChat = room.id
                mainStack.push (Qt.resolvedUrl("../pages/ChatSettingsPage.qml"))
            }
        }
        ]
    }
}
