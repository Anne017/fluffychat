import QtQuick 2.4
import Ubuntu.Components 1.3

/* =============================== MATRIX CONTROLLER ===============================

The matrix controller handles all requests to the matrix server. There are also
functions to login, logout and to autologin, when there are saved login
credentials
*/

Item {

    // The username and the device name at the current server
    property var username
    property var deviceName
    property var matrixid: "@" + username + ":" + server
    property var displayname

    // The token to identify
    property var token

    // The server of the user WITHOUT "/" at the end!
    property var server

    // The online status (bool)
    property var onlineStatus: false


    // Check if there are username, password and domain saved from a previous
    // session and autoconnect with them. If not, then just go to the login Page.
    function init () {
        storage.getConfig("token", function(res) { token = res })
        storage.getConfig("username", function(res) { username = res })
        storage.getConfig("domain", function(res) { server = res })

        if ( username != null && token != null && server != null ) {
            mainStack.push(Qt.resolvedUrl("../pages/ChatListPage.qml"))
            onlineStatus = true
            usernames.getById(matrix.matrixid, "", function (name) { displayname = name } )
            events.init ()
        }
        else {
            mainStack.push(Qt.resolvedUrl("../pages/LoginPage.qml"))
        }
    }


    // Login and set username, token and server! Needs to be done, before anything else
    function login ( newUsername, newPassword, newServer, newDeviceName, callback, error_callback, status_callback ) {
        server = newServer.toLowerCase()
        username = newUsername.toLowerCase()
        deviceName = newDeviceName
        var data = {
            "initial_device_display_name": newDeviceName,
            "user": newUsername,
            "password": newPassword,
            "type": "m.login.password"
        }

        var onLogged = function ( response ) {
            storage.setConfig ( "username", username )
            storage.setConfig ( "domain", server )
            storage.setConfig ( "token", response.access_token )
            token = response.access_token
            onlineStatus = true
            events.init ()
            if ( callback ) callback ( response )
        }
        xmlRequest ( "POST", data, "/client/r0/login", onLogged, error_callback, status_callback )
    }

    function logout ( callback, error_callback, status_callback ) {
        storage.unsetConfig ( "username")
        storage.unsetConfig ( "token")
        storage.unsetConfig ( "domain")
        storage.unsetConfig ( "next_batch")
        storage.drop ()
        onlineStatus = false
        username = server = token = events.since = undefined
        if ( !onlineStatus ) {
            if ( error_callback ) error_callback ( "Error! You are offline!" )
            return
        }
        xmlRequest ( "POST", {}, "/client/r0/logout", callback, error_callback, status_callback )
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

        var requestUrl = "https://" + server + "/_matrix" + action + getData
        var longPolling = (data != null && data.timeout)
        http.open( type, requestUrl, true);
        http.setRequestHeader('Content-type', 'application/json; charset=utf-8')
        http.timeout = defaultTimeout
        if ( token ) http.setRequestHeader('Authorization', 'Bearer ' + token);
        http.onreadystatechange = function() {
            if ( status_callback ) status_callback ( http.readyState )
            if (http.readyState === XMLHttpRequest.DONE) {
                if ( !longPolling ) progressBarRequests--
                if ( progressBarRequests < 0 ) progressBarRequests = 0
                try {
                    var responseType = http.getResponseHeader("Content-Type")
                    if ( http.responseText === "" ) throw( "offline" )
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
                    console.error("There was an error: When calling ", requestUrl, " With data: ", JSON.stringify(data), " Error-Report: ", error, http.responseText)
                    if ( error === "offline" && token ) {
                        onlineStatus = false
                        toast.show (i18n.tr("It seems that you are offline 😕"))
                    }
                    if ( typeof error === "string" ) error = {"errcode": "ERROR", "error": error}
                    if ( error_callback ) error_callback ( error )
                    else toast.show ( error.error )
                }
            }
        }
        if ( !longPolling ) progressBarRequests++

        http.send( JSON.stringify( postData ) );

        // Make timeout working in qml
        if ( !longPolling ) {
            function Timer() {
                return Qt.createQmlObject("import QtQuick 2.0; Timer {}", root);
            }
            var timer = new Timer();
            timer.interval = defaultTimeout;
            timer.repeat = false;
            timer.triggered.connect(function () {
                if (http.readyState !== XMLHttpRequest.DONE) http.abort ()
            })
            timer.start();
        }

        return http
    }



}
