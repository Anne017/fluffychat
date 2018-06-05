import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import "../components"

Rectangle {
    property var event
    width: root.width
    height: bubble.height + units.gu(1)
    color: "transparent"

    function update () {
        eventLabel.text = displayEvents.getDisplay ( event ) + " <font color='" + UbuntuColors.silk + "'>" + stamp.getChatTime ( event.origin_server_ts ) + "</font>"
    }

    Rectangle {
        id: bubble
        z: 2
        anchors.centerIn: parent
        border.width: 1
        border.color: UbuntuColors.silk
        color: "#FFFFFF"
        radius: 50
        height: eventLabel.height + units.gu(2)
        width: eventLabel.width + units.gu(2)

        Label {
            id: eventLabel
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: units.gu(1)
            Component.onCompleted: {
                var maxWidth = root.width - units.gu(4)
                if ( width > maxWidth ) width = maxWidth
            }
            wrapMode: Text.Wrap
            text: displayEvents.getDisplay ( event ) + " <font color='" + UbuntuColors.silk + "'>" + stamp.getChatTime ( event.origin_server_ts ) + "</font>"
            textSize: Label.Small
            font.italic: true
        }
    }
}
