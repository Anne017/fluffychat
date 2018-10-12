import QtQuick 2.4
import Ubuntu.Components 1.3

/*============================= ROOMNAME CONTROLLER ============================
The roomname controller is just a little helper to get the room display name
from a room address, such like: "!dasdj89j32@matrix.org"
*/

Item {
    // This function detects the room name of a chatroom.
    // Unfortunetly we need a callback function, because of the sql queries ...
    function getById ( chat_id, callback ) {
        var displayname = i18n.tr('Empty chat')
        storage.transaction( "SELECT topic FROM Chats WHERE id='" + chat_id + "'", function (rs) {
            if ( rs.rows.length > 0 && rs.rows[0].topic && rs.rows[0].topic !== "" ) {
                if ( callback )  ( rs.rows[0].topic )
            }
            else {
                // If it is a one on one chat, then use the displayname of the buddy
                storage.query( "SELECT Users.displayname, Users.matrix_id FROM Users, Memberships " +
                " WHERE Memberships.matrix_id=Users.matrix_id " +
                " AND Memberships.chat_id=? " +
                " AND Memberships.membership='join' " +
                " AND Memberships.matrix_id!=? ",
                [ chat_id, matrix.matrixid ], function (rs) {
                    var displayname = i18n.tr('Empty chat')
                    if ( rs.rows.length > 0 ) {
                        displayname = ""
                        for ( var i = 0; i < rs.rows.length; i++ ) {
                            var username = rs.rows[i].displayname || usernames.transformFromId ( rs.rows[i].matrix_id )
                            if ( rs.rows[i].state_key !== matrix.matrixid ) displayname += username + ", "
                        }
                        displayname = displayname.substr(0, displayname.length-2)
                        if ( displayname === "" || displayname === null ) displayname = i18n.tr('Empty chat')
                    }
                    if ( callback ) callback ( displayname )
                    // Else, use the default: "Empty chat"
                })
            }
        })
        return displayname
    }


    function getAvatarUrl ( chat_id, callback ) {
        storage.transaction( "SELECT avatar_url FROM Chats " +
        " WHERE id='" + chat_id + "' ",
        function (rs) {
            if ( rs.rows.length > 0 && rs.rows[0].avatar_url !== "" ) callback ( rs.rows[0].avatar_url )
            else getAvatarFromSingleChat ( chat_id, callback )
        })
    }


    function getAvatarFromSingleChat ( chat_id, callback ) {
        storage.query( "SELECT Users.avatar_url FROM Users, Memberships " +
        " WHERE Memberships.matrix_id=Users.matrix_id " +
        " AND Memberships.chat_id=? " +
        " AND Memberships.membership='join' " +
        " AND Memberships.matrix_id!=? ",
        [ chat_id, matrix.matrixid ], function (rs) {
            if ( rs.rows.length === 1 ) callback ( rs.rows[0].avatar_url )
            else callback ( "" )
        })
        return ""
    }
}
