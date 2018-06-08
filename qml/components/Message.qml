import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import "../components"

Rectangle {
    property var event
    property var sending: event.sending || false
    property var sent: event.sender.toLowerCase() === matrix.matrixid.toLowerCase()

    width: root.width
    height: messageBubble.height + units.gu(1)
    color: "transparent"
    opacity: sending ? 0.5 : 1

    function update () {
        metaLabel.text = (event.displayname || event.sender) + " " + stamp.getChatTime ( event.origin_server_ts )
        avatar.mxc = event.avatar_url
    }

    Avatar {
        id: avatar
        //name: "contact"
        mxc: event.avatar_url
        anchors.left: sent ? undefined : parent.left
        anchors.right: sent ? parent.right : undefined
        anchors.top: parent.top
        anchors.leftMargin: units.gu(1)
        anchors.rightMargin: units.gu(1)
        opacity: event.sameSender ? 0 : 1
    }

    Rectangle {
        id: messageBubble
        z: 2
        anchors.left: sent ? undefined : avatar.right
        anchors.right: sent ? avatar.left : undefined
        anchors.top: parent.top
        anchors.leftMargin: units.gu(1)
        anchors.rightMargin: units.gu(1)
        border.width: 1
        border.color: UbuntuColors.silk
        anchors.margins: 5
        color: sent ? "#FFFFFF" : mainColor
        radius: 50
        height: messageLabel.height + metaLabel.height + units.gu(2)
        width: Math.max( messageLabel.width, metaLabel.width ) + units.gu(2) + (event.sending ? units.gu(2) : 0)

        Text {
            id: messageLabel
            text: event.content_body
            color: sent ? "black" : "white"
            wrapMode: Text.Wrap
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: units.gu(1)
            onLinkActivated: Qt.openUrlExternally(link)
            Component.onCompleted: {
                var maxWidth = root.width - avatar.width - units.gu(8)
                if ( width > maxWidth ) width = maxWidth
                var urlRegex = /(https?:\/\/[^\s]+)/g;
                text = text.replace(urlRegex, function(url) {
                    return '<a href="%1"><font color="%2">%1</font></a>'.arg(url).arg(messageLabel.color)
                })
            }
        }
        Label {
            id: metaLabel
            text: (event.displayname || event.sender) + " " + stamp.getChatTime ( event.origin_server_ts )
            anchors.top: messageLabel.bottom
            anchors.left: parent.left
            anchors.leftMargin: units.gu(1)
            color: UbuntuColors.silk
            textSize: Label.Small
        }

        ActivityIndicator {
            id: activity
            visible: sending
            running: visible
            anchors.left: metaLabel.right
            anchors.top: messageLabel.bottom
            anchors.leftMargin: units.gu(0.5)
            width: units.gu(1.5)
            height: width
        }
    }


}
