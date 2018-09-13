import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Connectivity 1.0

/* =============================== MATRIX CONTROLLER ===============================

The matrix controller handles all requests to the matrix server. There are also
functions to login, logout and to autologin, when there are saved login
credentials
*/

Item {

    property var matrixid: settings.server ? "@" + settings.username + ":" + settings.server.split(":")[0] : null

    // The online status (bool)
    property var onlineStatus: false

    // The list of the current active requests, to prevent multiple same requests
    property var activeRequests: []

    // Check if there are username, password and domain saved from a previous
    // session and autoconnect with them. If not, then just go to the login Page.
    function init () {

        if ( settings.token ) {
            if ( tabletMode ) mainStack.push(Qt.resolvedUrl("../pages/BlankPage.qml"))
            else mainStack.push(Qt.resolvedUrl("../pages/ChatListPage.qml"))
            onlineStatus = true
            usernames.getById(matrix.matrixid, "", function (name) { settings.displayname = name } )
            events.init ()
            resendAllMessages ()
        }
        else {
            mainStack.push(Qt.resolvedUrl("../pages/LoginPage.qml"))
        }
    }


    // Login and set username, token and server! Needs to be done, before anything else
    function login ( newUsername, newPassword, newServer, newDeviceName, callback, error_callback, status_callback ) {

        settings.username = newUsername.toLowerCase()
        settings.server = newServer.toLowerCase()
        settings.deviceName = newDeviceName

        var data = {
            "initial_device_display_name": newDeviceName,
            "user": newUsername,
            "password": newPassword,
            "type": "m.login.password"
        }

        var onLogged = function ( response ) {
            settings.token = response.access_token
            settings.deviceID = response.device_id
            settings.username = (response.user_id.substr(1)).split(":")[0]
            settings.server = newServer.toLowerCase()
            settings.deviceName = newDeviceName
            settings.dbversion = storage.version
            onlineStatus = true
            events.init ()
            if ( callback ) callback ( response )
        }

        var onError = function ( response ) {
            settings.username = settings.server = settings.deviceName = undefined
            if ( error_callback ) error_callback ( response )
        }
        xmlRequest ( "POST", data, "/client/r0/login", onLogged, error_callback, status_callback )
    }

    function logout () {
        if ( events.syncRequest ) {
            events.abortSync = true
            events.syncRequest.abort ()
            events.abortSync = false
        }
        var callback = function () { post ( "/client/r0/logout", {}, reset, reset ) }
        pushclient.setPusher ( false, callback, callback )
    }


    function reset () {
        storage.drop ()
        onlineStatus = false
        settings.username = settings.server = settings.token = settings.pushToken = settings.deviceID = settings.deviceName = settings.displayname = settings.avatar_url = settings.since = undefined
        mainStack.clear ()
        mainStack.push(Qt.resolvedUrl("../pages/LoginPage.qml"))
    }


    // This function helps to send a message. It automatically repeats, if there
    // was an error with the connection.
    function sendMessage ( messageID, data, chat_id, callback ) {
        console.log("try now ...",messageID)
        if ( !Connectivity.online ) return
        var msgtype = data.msgype === "m.text" ? "m.room.message" : data.msgype
        matrix.put( "/client/r0/rooms/" + chat_id + "/send/" + msgtype + "/" + messageID, data, function ( response ) {
            storage.transaction ( "SELECT * FROM Events WHERE id='" + response.event_id + "'", function ( res ) {
                if ( res.rows.length > 0 ) {
                    storage.transaction ( "DELETE FROM Events WHERE id='" + messageID + "'", callback )
                }
                else {
                    storage.transaction ( "UPDATE Events SET id='" + response.event_id + "', status=1 WHERE id='" + messageID + "'", callback )
                }

            })
        }, function ( error ) {
            console.warn("Error ... ", error.errcode, ": ", error.error)

            // If the user has no permissions or there is an internal server error,
            // the message gets deleted
            if ( error.errcode === "M_FORBIDDEN" ) {
                toast.show ( i18n.tr("You do not have permission to write to this chat.") )
                storage.transaction ( "DELETE FROM Events WHERE id='" + messageID + "'", callback )
            }
            else if ( error.errcode === "M_UNKNOWN" ) {
                toast.show ( error.error )
                storage.transaction ( "DELETE FROM Events WHERE id='" + messageID + "'", callback )
            }
            // Else: Try again in a few seconds
            else if ( Connectivity.online ) {
                function Timer() {
                    return Qt.createQmlObject("import QtQuick 2.0; Timer {}", root)
                }
                var timer = new Timer()
                timer.interval = miniTimeout
                timer.repeat = false
                timer.triggered.connect(function () {
                    var newMessageID = "%" + new Date().getTime();
                    storage.transaction ( "UPDATE Events SET id='" + newMessageID + "', status=1 WHERE id='" + messageID + "'", function () {
                        sendMessage ( newMessageID, data, chat_id, callback )
                    } )
                })
                timer.start();
            }

        } )
    }


    // If the user starts the app or is online again, all sending messages should
    // restart sending
    function resendAllMessages () {
        console.log("resend all sending events")
        storage.transaction ( "SELECT id, chat_id, content_body FROM Events WHERE status=0", function ( rs) {
            if ( rs.rows.length === 0 ) return
            var event = rs.rows[0]
            var data = {
                msgtype: "m.text",
                body: event.content_body
            }
            console.log("Sending:", event.id, event.content_body, event.chat_id)
            sendMessage ( event.id, data, event.chat_id, function (){} )
            if ( rs.rows.length > 1 ) {
                function Timer() {
                    return Qt.createQmlObject("import QtQuick 2.0; Timer {}", root)
                }
                var timer = new Timer()
                timer.interval = miniTimeout
                timer.repeat = false
                timer.triggered.connect(resendAllMessages)
                timer.start();
            }
        } )
    }


    // Accept all invitations automatically
    function autoAcceptInvitations () {
        console.log("Auto accept invitations ...")
        storage.transaction ( "SELECT id FROM Chats WHERE membership='invite'", function ( rs ) {
            if ( rs.rows.length === 0 ) return
            loadingScreen.visible = true
            matrix.post("/client/r0/join/" + encodeURIComponent(rs.rows[0].id), null, function () {
                events.waitForSync ()
                if ( rs.rows.length > 1 ) autoAcceptInvitations ()
            })
        })
    }


    Connections {
        target: Connectivity
        onOnlineChanged: if ( Connectivity.online ) resendAllMessages ()
    }


    function get ( action, data, callback, error_callback, status_callback ) {
        return xmlRequest ( "GET", data, action, callback, error_callback, status_callback )
    }

    function post ( action, data, callback, error_callback, status_callback) {
        return xmlRequest ( "POST", data, action, callback, error_callback, status_callback )
    }

    function put ( action, file, callback, error_callback, status_callback ) {
        return xmlRequest ( "PUT", file, action, callback, error_callback, status_callback )
    }

    // Needs the name remove, because delete is reserved
    function remove ( action, file, callback, error_callback, status_callback ) {
        return xmlRequest ( "DELETE", file, action, callback, error_callback, status_callback )
    }

    function xmlRequest ( type, data, action, callback, error_callback, status_callback ) {

        // Check if the same request is actual sent
        var checksum = type + JSON.stringify(data) + action
        if ( activeRequests.indexOf(checksum) !== -1 ) return console.warn( "multiple request detected!" )
        else activeRequests.push ( checksum )

        var http = new XMLHttpRequest();
        var postData = {}
        var getData = ""

        if ( type === "GET" && data != null ) {
            for ( var i in data ) {
                getData += "&" + i + "=" + encodeURIComponent(data[i])
            }
            getData = "?" + getData.substr(1)
            //getData = getData.replace("")
        }
        else if ( data != null ) postData = data

        function Timer() {
            return Qt.createQmlObject("import QtQuick 2.0; Timer {}", root)
        }
        var timer = new Timer()

        var requestUrl = "https://" + settings.server + "/_matrix" + action + getData
        var longPolling = (data != null && data.timeout)
        http.open( type, requestUrl, true);
        http.setRequestHeader('Content-type', 'application/json; charset=utf-8')
        http.timeout = defaultTimeout
        if ( settings.token ) http.setRequestHeader('Authorization', 'Bearer ' + settings.token);
        http.onreadystatechange = function() {
            if ( status_callback ) status_callback ( http.readyState )
            if (http.readyState === XMLHttpRequest.DONE) {
                timer.stop ()
                var index = activeRequests.indexOf(checksum);
                activeRequests.splice( index, 1 )
                if ( !longPolling ) progressBarRequests--
                if ( progressBarRequests < 0 ) progressBarRequests = 0
                try {
                    var responseType = http.getResponseHeader("Content-Type")
                    if ( http.responseText === "" ) throw( "No connection to the homeserver 😕" )
                    if ( responseType === "application/json" ) {
                        var response = JSON.parse(http.responseText)
                        if ( "errcode" in response ) throw response
                        if ( callback ) callback( response )
                    }
                    else if ( responseType = "image/png" ) {
                        if ( callback ) callback( http.responseText )
                    }
                }
                catch ( error ) {
                console.error("There was an error: When calling ", requestUrl, " With data: ", JSON.stringify(data), " Error-Report: ", error/*, http.responseText*/)
                if ( typeof error === "string" ) error = {"errcode": "ERROR", "error": error}
                if ( error.errcode === "M_UNKNOWN_TOKEN" ) reset ()
                if ( !error_callback && error === "offline" && settings.token ) {
                    onlineStatus = false
                    toast.show (i18n.tr("No connection to the homeserver 😕"))
                }
                else if ( error.errcode === "M_CONSENT_NOT_GIVEN") {
                    var url = "https://" + error.error.split("https://")[1]
                    url = url.substring(0, url.length - 1);
                    console.log("Die url ist: '" + url + "'")
                    Qt.openUrlExternally( url )
                }
                else if ( error_callback ) error_callback ( error )
                else if ( error.errcode !== undefined && error.error !== undefined ) toast.show ( error.errcode + ": " + error.error )
            }
        }
    }
    if ( !longPolling ) {
        progressBarRequests++
    }

    // Make timeout working in qml

    timer.interval = (longPolling || action == "/client/r0/sync") ? longPollingTimeout+2000 : defaultTimeout
    timer.repeat = false
    timer.triggered.connect(function () {
        console.log("timeout :-/")
        if (http.readyState === XMLHttpRequest.OPENED) http.abort ()
    })
    timer.start();
    http.send( JSON.stringify( postData ) );

    return http
}


function upload ( path, callback, error_callback ) {
    console.log("Uploading ...", path)
    var pathparts = path.split("/")
    var filename = pathparts [ pathparts.length - 1 ]
    var type = filename.split(".")[1]

    // Send the blob to the server
    var requestUrl = "https://" + settings.server + "/_matrix/media/r0/upload?filename=" + filename
    //Fluffychat.upload ( path, requestUrl, 'Bearer ' + settings.token )
    callback ( "Ready ..." )
}


function getThumbnailFromMxc ( mxc, width, height ) {
    if ( mxc === undefined ) return ""

    var mxcID = mxc.replace("mxc://","")
    return "https://" + settings.server + "/_matrix/media/r0/thumbnail/" + mxcID + "/?width=" + width + "&height=" + height + "&method=crop"
}



function getImageLinkFromMxc ( mxc ) {
    if ( mxc === undefined ) return ""
    var mxcID = mxc.replace("mxc://","")
    return "https://" + settings.server + "/_matrix/media/r0/download/" + mxcID + "/"
}




}
