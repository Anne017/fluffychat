import QtQuick 2.9
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import "../components"

Page {
    anchors.fill: parent

    property var enabled: true
    property var inviteList: []
    property var selectedCount: 0

    // To disable the background image on this page
    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.background
    }

    header: FcPageHeader {
        id: header
        title: i18n.tr('Invite user: %1 selected').arg(selectedCount)
    }

    function invite ( i ) {
        if ( i >= inviteList.length ) return mainStack.pop()
        enabled = false
        matrix.post ( "/client/r0/rooms/%1/invite".arg(activeChat),
        { user_id: inviteList[i] }, function () { invite( i+1 ) } )
    }

    Component.onCompleted: {
        storage.transaction( "SELECT Users.matrix_id, Users.displayname, Users.avatar_url, Contacts.medium, Contacts.address FROM Users LEFT JOIN Contacts " +
        " ON Contacts.matrix_id=Users.matrix_id ORDER BY Contacts.medium DESC LIMIT 1000",
        function( res )  {
            for( var i = 0; i < res.rows.length; i++ ) {
                var user = res.rows[i]
                model.append({
                    matrix_id: user.matrix_id,
                    displayname: user.displayname || usernames.transformFromId(user.matrix_id),
                    avatar_url: user.avatar_url,
                    temp: false
                })
            }
        })
    }

    TextField {
        id: searchField
        objectName: "searchField"
        property var searchMatrixId: false
        property var upperCaseText: displayText.toUpperCase()
        property var tempElement: null
        z: 5
        anchors {
            top: header.bottom
            topMargin: units.gu(1)
            bottomMargin: units.gu(1)
            left: parent.left
            right: parent.right
            rightMargin: units.gu(2)
            leftMargin: units.gu(2)
        }
        readOnly: !enabled
        focus: true
        inputMethodHints: Qt.ImhNoPredictiveText
        placeholderText: i18n.tr("Search for example @username:server.abc")
        onDisplayTextChanged: {
            searchMatrixId = displayText.slice( 0,1 ) === "@"

            if ( searchMatrixId && displayText.indexOf(":") !== -1 ) {
                if ( tempElement !== null ) {
                    model.remove ( tempElement)
                    tempElement = null
                }
                model.append ( {
                    matrix_id: displayText,
                    displayname: displayText,
                    avatar_url: "",
                    temp: true
                })
                tempElement = model.count - 1
            }
        }
    }

    ActivityIndicator {
        visible: !enabled
        running: visible
        anchors.centerIn: parent
    }

    ListView {
        opacity: enabled ? 1 : 0.5
        id: chatListView
        width: parent.width
        height: parent.height - 2*header.height - searchField.height
        anchors.top: searchField.bottom
        delegate: SettingsListCheck {}
        model: ListModel { id: model }
    }

    Rectangle {
        height: header.height
        width: parent.width
        anchors.bottom: parent.bottom

        Button {
            text: i18n.tr("Invite")
            width: parent.width - units.gu(4)
            color: UbuntuColors.green
            anchors.centerIn: parent
            onClicked: invite ( 0 )
        }
    }
}
