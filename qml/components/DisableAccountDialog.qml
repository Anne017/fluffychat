import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Component {
    id: dialog

    Dialog {
        id: dialogue
        title: i18n.tr("Disable your account")
        Icon {
            name: "security-alert"
            width: parent.width
            height: width
        }
        Label {
            text: i18n.tr("Are you sure, that you want to disable your account? This can not be undone!")
            color: UbuntuColors.red
            width: parent.width
            wrapMode: Text.Wrap
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
                text: i18n.tr("Disable")
                color: UbuntuColors.red
                onClicked: {
                    var callback = function () { matrix.post ( "/client/r0/account/deactivate", null ) }
                    pushclient.setPusher ( false, callback, callback )
                }
            }
        }
    }
}
