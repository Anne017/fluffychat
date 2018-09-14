import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import "../components"

ListItem {

    visible: { layout.title.text.toUpperCase().indexOf( searchField.displayText.toUpperCase() ) !== -1 }
    height: visible ? layout.height : 0

    onClicked: usernames.showUserSettings ( matrixid )

    ListItemLayout {
        id: layout
        title.text: name

        Avatar {
            name: layout.title.text
            SlotsLayout.position: SlotsLayout.Leading
            mxc: avatar_url || ""
            onClickFunction: function () {
                usernames.showUserSettings ( matrixid )
            }
        }
    }
}
