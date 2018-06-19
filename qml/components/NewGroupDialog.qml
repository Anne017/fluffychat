import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Component {
    id: dialog

    Dialog {
        id: dialogue
        title: i18n.tr("New group")
        Icon {
            name: "contact-group"
            width: parent.width
            height: width
        }
        TextField {
            id: groupTextField
            placeholderText: i18n.tr("Group name")
        }
        Row {
            width: parent.width
            spacing: units.gu(1)
            Button {
                width: (parent.width - units.gu(1)) / 2
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(dialogue)
            }
            Button {
                width: (parent.width - units.gu(1)) / 2
                text: i18n.tr("Continue")
                enabled: groupTextField.displayText !== ""
                color: UbuntuColors.green
                onClicked: {

                    events.waitForSync ()
                    var roomname = groupTextField.displayText
                    var data = {
                        "room_alias_name": groupTextField.displayText,
                        "name": groupTextField.displayText
                    }
                    matrix.post( "/client/r0/createRoom", data, success_callback )

                    PopupUtils.close(dialogue)
                }
            }
        }
    }
}
