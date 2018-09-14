import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Connectivity 1.0


/* =============================== EVENT CONTROLLER ===============================

The event controller is responsible for handling all events and stay connected
with the matrix homeserver via a long polling http request

To try fluffychat with clickable --desktop you need to remove the line:
import Ubuntu.Connectivity 1.0
and the Connections{ } to Connectivity down there
*/
Item {

    property var statusMap: ["Offline", "Connecting", "Online"]

    Connections {
        target: Connectivity
        // full status can be retrieved from the base C++ class
        // status property
        onOnlineChanged: if ( Connectivity.online ) restartSync ()
    }

    signal chatListUpdated ( var response )
    signal chatTimelineEvent ( var response )

    property var syncRequest: null
    property var initialized: false
    property var abortSync: false

    function init () {

        // Set the pusher if it is not set
        if ( settings.pushToken !== pushtoken ) {
            console.log("👷 Trying to set pusher ...")
            pushclient.setPusher ( true, function () {
                settings.pushToken = pushtoken
                console.log("😊 Pusher is set!")
            } )
        }

        // Start synchronizing
        initialized = true
        if ( settings.since ) {
            waitForSync ()
            return sync ( 1 )
        }

        loadingScreen.visible = true
        matrix.get( "/client/r0/sync", { filter: "{\"room\":{\"include_leave\":true}}" }, function ( response ) {
            if ( waitingForSync ) progressBarRequests--
            handleEvents ( response )
            matrix.onlineStatus = true
            if ( !abortSync ) sync ()
        }, init, null, longPollingTimeout )
    }

    function sync ( timeout ) {

        if ( settings.token === null || settings.token === undefined || abortSync ) return

        var data = { "since": settings.since }

        if ( !timeout ) data.timeout = longPollingTimeout

        syncRequest = matrix.get ("/client/r0/sync", data, function ( response ) {

            if ( waitingForSync ) progressBarRequests--
            waitingForSync = false
            if ( settings.token ) {
                matrix.onlineStatus = true
                handleEvents ( response )
                sync ()
            }
        }, function ( error ) {
            if ( !abortSync && settings.token !== undefined ) {
                matrix.onlineStatus = false
                if ( error.errcode === "M_INVALID" ) {
                    mainStack.clear ()
                    mainStack.push(Qt.resolvedUrl("../pages/LoginPage.qml"))
                }
                else {
                    if ( Connectivity && Connectivity.online ) restartSync ()
                    else toast.show ( i18n.tr("You are offline 😕") )
                    console.log ( "Synchronization error! Try to restart ..." )
                }
            }
        } );
    }


    function restartSync () {
        if ( syncRequest === null ) return
        console.log("resync")
        if ( syncRequest ) {
            console.log( "Stopping latest sync" )
            abortSync = true
            syncRequest.abort ()
            abortSync = false
        }
        sync ( true )
    }


    function waitForSync () {
        if ( waitingForSync ) return
        waitingForSync = true
        progressBarRequests++
    }


    function stopWaitForSync () {
        if ( !waitingForSync ) return
        waitingForSync = false
        progressBarRequests--
    }

    property var transaction


    // This function starts handling the events, saving new data in the storage,
    // deleting data, updating data and call signals
    function handleEvents ( response ) {

        //console.log( "===== NEW SYNC:", JSON.stringify( response ) )
        var changed = false
        var timecount = new Date().getTime()
        try {
            storage.db.transaction(
                function(tx) {
                    transaction = tx
                    handleRooms ( response.rooms.join, "join" )
                    handleRooms ( response.rooms.leave, "leave" )
                    handleRooms ( response.rooms.invite, "invite" )

                    settings.since = response.next_batch
                    triggerSignals ( response )
                    loadingScreen.visible = false
                    //console.log("===> RECEIVED RESPONSE! SYNCHRONIZATION performance: ", new Date().getTime() - timecount )
                }
            )
        }
        catch ( e ) {
            toast.show ( i18n.tr("😰 A critical error has occurred! Sorry, the connection to the server has ended! Please report this bug on: https://github.com/ChristianPauly/fluffychat/issues/new") )
            console.log ( e )
            abortSync = true
            syncRequest.abort ()
            return
        }
    }


    function triggerSignals ( response ) {
        var activeRoom = response.rooms.join[activeChat]

        chatListUpdated ( response )

        // Is there a new chat timeline event in the active room?
        if ( activeRoom !== undefined ) chatTimelineEvent ( activeRoom )
    }


    // Handling the synchronization events starts with the rooms, which means
    // that the informations should be saved in the database
    function handleRooms ( rooms, membership ) {
        for ( var id in rooms ) {
            var room = rooms[id]

            // If the membership of the user is "leave" then the chat and all
            // events and user-memberships should be removed.
            // If not, it is "join" or "invite" and everything should be saved

            // Insert the chat into the database if not exists
            transaction.executeSql ("INSERT OR IGNORE INTO Chats " +
            "VALUES('" + id + "', '" + membership + "', '', 0, 0, 0, '', '', '', '', '', '', '', '', '', 0, 50, 50, 0, 50, 50, 0, 50, 100, 50, 50, 50, 100) ")
            // Update the notification counts and the limited timeline boolean
            transaction.executeSql ( "UPDATE Chats SET " +
            " highlight_count=" +
            (room.unread_notifications && room.unread_notifications.highlight_count || 0) +
            ", notification_count=" +
            (room.unread_notifications && room.unread_notifications.notification_count || 0) +
            ", membership='" +
            membership +
            "', limitedTimeline=" +
            (room.timeline ? (room.timeline.limited ? 1 : 0) : 0) +
            " WHERE id='" + id + "' ")

            // Handle now all room events and save them in the database
            if ( room.state ) handleRoomEvents ( id, room.state.events, "state", room )
            if ( room.invite_state ) handleRoomEvents ( id, room.invite_state.events, "invite_state", room )
            if ( room.timeline ) {
                // Is the timeline limited? Then all previous messages should be
                // removed from the database!
                if ( room.timeline.limited ) {
                    transaction.executeSql ("DELETE FROM Events WHERE chat_id='" + id + "'")
                    transaction.executeSql ("UPDATE Chats SET prev_batch='" + room.timeline.prev_batch + "' WHERE id='" + id + "'")
                }
                handleRoomEvents ( id, room.timeline.events, "timeline", room )
            }
            if ( room.ephemeral ) handleEphemeral ( id, room.ephemeral.events )
        }
    }


    // Handle ephemerals (message receipts)
    function handleEphemeral ( id, events ) {
        for ( var i = 0; i < events.length; i++ ) {
            if ( events[i].type === "m.receipt" ) {
                for ( var e in events[i].content ) {
                    for ( var user in events[i].content[e]["m.read"]) {
                        var timestamp = events[i].content[e]["m.read"][user].ts
                        transaction.executeSql ( "UPDATE Events SET status=3 WHERE origin_server_ts<=" + timestamp +
                        " AND chat_id='" + id + "' AND status=2")
                    }
                }
            }
        }
    }


    // Events are all changes in a room
    function handleRoomEvents ( roomid, events, type ) {

        // We go through the events array
        for ( var i = 0; i < events.length; i++ ) {
            var event = events[i]

            // messages from the timeline will be saved, for display in the chat.
            // Only this events will call the notification signal or change the
            // current displayed chat!
            if ( type === "timeline" || type === "history" ) {
                var status = type === "timeline" ? msg_status.RECEIVED : msg_status.HISTORY
                transaction.executeSql ( "INSERT OR REPLACE INTO Events VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)",
                [ event.event_id,
                roomid,
                event.origin_server_ts,
                event.sender,
                event.content.body || null,
                event.content.msgtype || null,
                event.type,
                JSON.stringify(event.content),
                status ])
            }


            // If this timeline only contain events from the history, from the past,
            // then all other changes to the room are old and should not be saved.
            if ( type === "history" ) continue

            // This event means, that the name of a room has been changed, so
            // it has to be changed in the database.
            if ( event.type === "m.room.name" ) {
                transaction.executeSql( "UPDATE Chats SET topic=? WHERE id=?",
                [ event.content.name,
                roomid ])
                // If the affected room is the currently used room, then the
                // name has to be updated in the GUI:
                if ( activeChat === roomid ) {
                    roomnames.getById ( roomid, function ( displayname ) {
                        activeChatDisplayName = displayname
                    })
                }
            }


            // This event means, that the topic of a room has been changed, so
            // it has to be changed in the database
            if ( event.type === "m.room.topic" ) {
                transaction.executeSql( "UPDATE Chats SET description=? WHERE id=?",
                [ event.content.topic || "",
                roomid ])
            }


            // This event means, that the canonical alias of a room has been changed, so
            // it has to be changed in the database
            if ( event.type === "m.room.canonical_alias" ) {
                transaction.executeSql( "UPDATE Chats SET canonical_alias=? WHERE id=?",
                [ event.content.alias || "",
                roomid ])
            }


            // This event means, that the topic of a room has been changed, so
            // it has to be changed in the database
            if ( event.type === "m.room.history_visibility" ) {
                transaction.executeSql( "UPDATE Chats SET history_visibility=? WHERE id=?",
                [ event.content.history_visibility,
                roomid ])
            }


            // This event means, that the topic of a room has been changed, so
            // it has to be changed in the database
            if ( event.type === "m.room.redaction" ) {
                transaction.executeSql( "DELETE FROM Events WHERE id=?",
                [ event.redacts ])
            }


            // This event means, that the topic of a room has been changed, so
            // it has to be changed in the database
            if ( event.type === "m.room.guest_access" ) {
                transaction.executeSql( "UPDATE Chats SET guest_access=? WHERE id=?",
                [ event.content.guest_access,
                roomid ])
            }


            // This event means, that the topic of a room has been changed, so
            // it has to be changed in the database
            if ( event.type === "m.room.join_rules" ) {
                transaction.executeSql( "UPDATE Chats SET join_rules=? WHERE id=?",
                [ event.content.join_rule,
                roomid ])
            }


            // This event means, that the avatar of a room has been changed, so
            // it has to be changed in the database
            else if ( event.type === "m.room.avatar" ) {
                transaction.executeSql( "UPDATE Chats SET avatar_url=? WHERE id=?",
                [ event.content.url,
                roomid ])
            }


            // This event means, that the aliases of a room has been changed, so
            // it has to be changed in the database
            if ( event.type === "m.room.aliases" ) {
                transaction.executeSql( "DELETE FROM Addresses WHERE chat_id='" + roomid + "'")
                for ( var alias = 0; alias < event.content.aliases.length; alias++ ) {
                    transaction.executeSql( "INSERT INTO Addresses VALUES(?,?)",
                    [ roomid, event.content.aliases[alias] ] )
                }
            }


            // This event means, that someone joined the room, has left the room
            // or has changed his nickname
            else if ( event.type === "m.room.member" ) {

                transaction.executeSql( "INSERT OR REPLACE INTO Users VALUES(?, ?, ?)",
                [ event.state_key,
                event.content.displayname,
                event.content.avatar_url ])

                transaction.executeSql( "INSERT OR REPLACE INTO Memberships VALUES('" + roomid + "', '" + event.state_key + "', ?, " +
                "COALESCE(" +
                "(SELECT power_level FROM Memberships WHERE chat_id='" + roomid + "' AND matrix_id='" + event.state_key + "'), " +
                "(SELECT power_user_default FROM Chats WHERE id='" + roomid + "')" +
                "))",
                [ event.content.membership ])

                if ( event.state_key === matrix.matrixid) {
                    settings.avatar_url = event.content.avatar_url
                    settings.displayname = event.content.displayname
                }
            }

            // This event changes the permissions of the users and the power levels
            else if ( event.type === "m.room.power_levels" ) {
                var query = "UPDATE Chats SET "
                if ( event.content.ban ) query += ", power_ban=" + event.content.ban
                if ( event.content.events_default ) query += ", power_events_default=" + event.content.events_default
                if ( event.content.state_default ) query += ", power_state_default=" + event.content.state_default
                if ( event.content.redact ) query += ", power_redact=" + event.content.redact
                if ( event.content.invite ) query += ", power_invite=" + event.content.invite
                if ( event.content.kick ) query += ", power_kick=" + event.content.kick
                if ( event.content.user_default ) query += ", power_user_default=" + event.content.user_default
                if ( event.content.events ) {
                    if ( event.content.events["m.room.avatar"] ) query += ", power_event_avatar=" + event.content.events["m.room.avatar"]
                    if ( event.content.events["m.room.history_visibility"] ) query += ", power_event_history_visibility=" + event.content.events["m.room.history_visibility"]
                    if ( event.content.events["m.room.canonical_alias"] ) query += ", power_event_canonical_alias=" + event.content.events["m.room.canonical_alias"]
                    if ( event.content.events["m.room.aliases"] ) query += ", power_event_aliases=" + event.content.events["m.room.aliases"]
                    if ( event.content.events["m.room.name"] ) query += ", power_event_name=" + event.content.events["m.room.name"]
                    if ( event.content.events["m.room.power_levels"] ) query += ", power_event_power_levels=" + event.content.events["m.room.power_levels"]
                }
                if ( query !== "UPDATE Chats SET ") {
                    query = query.replace(",","")
                    transaction.executeSql( query + " WHERE id=?",[ roomid ])
                }

                // Set the users power levels:
                if ( event.content.users ) {
                    for ( var user in event.content.users ) {
                        transaction.executeSql( "UPDATE Memberships SET power_level=? WHERE matrix_id=? AND chat_id=?",
                        [ event.content.users[user],
                        user,
                        roomid ])
                    }
                }
            }
        }
    }
}
