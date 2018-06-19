import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3

ListItem {
    property var name: ""
    property var icon: "settings"
    property alias isChecked: switcher.checked
    property alias isEnabled: switcher.enabled
    property var onSwitching
    property var iconColor: settings.mainColor
    height: layout.height

    ListItemLayout {
        id: layout
        title.text: name
        Icon {
            name: icon
            color: iconColor
            width: units.gu(4)
            height: units.gu(4)
            SlotsLayout.position: SlotsLayout.Leading
        }

        Switch {
            id: switcher
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: units.gu(2)
            onCheckedChanged: onSwitching ()
        }
    }
    onClicked: switcher.checked ? switcher.checked = false : switcher.checked = true
}
