import QtQuick 2.4
import Ubuntu.Components 1.3

/*============================= ROOMNAME CONTROLLER ============================
The roomname controller is just a little helper to get the room display name
from a room address, such like: "!dasdj89j32@matrix.org"
*/

Item {
    // This function detects the room name of a chatroom.
    // Unfortunetly we need a callback function, because of the sql queries ...
    function getById ( chatid, callback ) {
        var displayname = i18n.tr('Empty chat')
        storage.transaction( "SELECT topic FROM Chats WHERE id='" + chatid + "'", function (rs) {
            if ( rs.rows.length > 0 && rs.rows[0].topic !== "" ) {
                callback ( rs.rows[0].topic )
            }
            else {
                // If it is a one on one chat, then use the displayname of the buddy
                storage.query( "SELECT displayname, membership, state_key FROM Users WHERE (membership='join' OR membership='invite') AND chat_id=? AND state_key!=?", [ chatid, matrix.matrixid ], function (rs) {
                    var displayname = i18n.tr('Empty chat')
                    if ( rs.rows.length > 0 ) {
                        displayname = ""
                        for ( var i = 0; i < rs.rows.length; i++ ) {
                            if ( rs.rows[i].state_key !== matrix.matrixid ) displayname += rs.rows[i].displayname + ", "
                        }
                        displayname = displayname.substr(0, displayname.length-2)
                        if ( displayname === "" || displayname === null ) displayname = i18n.tr('Empty chat')
                    }
                    callback ( displayname )
                    // Else, use the default: "Empty chat"
                })
            }
        })
    }
}
