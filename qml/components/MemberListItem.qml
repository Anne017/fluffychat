import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import "../components"

ListItem {
    height: layout.height

    onClicked: {
        newContactMatrixID = matrixid
        PopupUtils.open( newContactDialog )
    }

    opacity: membership === "leave" ? 0.5 : 1

    ListItemLayout {
        id: layout
        title.text: name
        subtitle.text: membership
        Avatar {
            name: layout.title.text
            SlotsLayout.position: SlotsLayout.Leading
            mxc: avatar_url || ""
        }
    }
}
