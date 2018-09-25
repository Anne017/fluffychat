import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import "../components"

Page {
    anchors.fill: parent

    header: FcPageHeader {
        title: i18n.tr('Theme')
    }

    MediaImport { id: backgroundImport }

    Connections {
        target: backgroundImport
        onMediaReceived: changeBackground ( mediaUrl )
    }

    function changeBackground ( mediaUrl ) {
        console.log( mediaUrl )
        settings.chatBackground = mediaUrl
    }

    ScrollView {
        id: scrollView
        width: parent.width
        height: parent.height - header.height
        anchors.top: header.bottom
        contentItem: Column {
            width: mainStackWidth

            SettingsListSwitch {
                name: i18n.tr("Dark mode")
                icon: "display-brightness-max"
                onSwitching: function () { settings.darkmode = isChecked }
                isChecked: settings.darkmode
                isEnabled: true
            }

            ListItem {
                property var name: ""
                property var icon: "settings"
                onClicked: backgroundImport.requestMedia ()
                height: layout.height

                ListItemLayout {
                    id: layout
                    title.text: i18n.tr("Change chat background")
                    Icon {
                        name: "image-x-generic-symbolic"
                        color: settings.mainColor
                        width: units.gu(4)
                        height: units.gu(4)
                        SlotsLayout.position: SlotsLayout.Leading
                    }

                    Rectangle {
                        id: removeIcon
                        SlotsLayout.position: SlotsLayout.Trailing
                        width: units.gu(4)
                        height: width
                        visible: settings.chatBackground !== undefined
                        color: settings.darkmode ? Qt.hsla( 0, 0, 0.04, 1 ) : Qt.hsla( 0, 0, 0.96, 1 )
                        border.width: 1
                        border.color: settings.darkmode ? UbuntuColors.slate : UbuntuColors.silk
                        radius: width / 6
                        MouseArea {
                            anchors.fill: parent
                            visible: settings.chatBackground !== undefined
                            onClicked: {
                                settings.chatBackground = undefined
                                toast.show ( i18n.tr("Background removed") )
                            }
                        }
                        Icon {
                            width: units.gu(2)
                            height: units.gu(2)
                            anchors.centerIn: parent
                            name: "edit-delete"
                            color: UbuntuColors.red
                            visible: settings.chatBackground !== undefined
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: units.gu(2)
                color: theme.palette.normal.background
            }

            Label {
                height: units.gu(2)
                anchors.left: parent.left
                anchors.leftMargin: units.gu(2)
                text: i18n.tr("Choose a main color:")
                font.bold: true
            }

            ColorListItem {
                name: i18n.tr("Purple")
                iconColor: defaultMainColor
                onClicked: settings.mainColor = iconColor
            }

            ColorListItem {
                name: i18n.tr("Blue")
                iconColor: UbuntuColors.blue
                onClicked: settings.mainColor = iconColor
            }

            ColorListItem {
                name: i18n.tr("Red")
                iconColor: UbuntuColors.red
                onClicked: settings.mainColor = iconColor
            }

            ColorListItem {
                name: i18n.tr("Orange")
                icon: "toolkit_arrow-right"
                iconColor: UbuntuColors.orange
                onClicked: settings.mainColor = iconColor
            }

            ColorListItem {
                name: i18n.tr("Graphite")
                iconColor: UbuntuColors.graphite
                onClicked: settings.mainColor = iconColor
            }

            ColorListItem {
                name: i18n.tr("Green")
                iconColor: UbuntuColors.green
                onClicked: settings.mainColor = iconColor
            }

        }
    }
}
