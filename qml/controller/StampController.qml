import QtQuick 2.4
import Ubuntu.Components 1.3

Item {

    function getChatTime ( stamp ) {
        var date = new Date ( stamp )
        var now = new Date ()
        var locale = Qt.locale()
        var fullTimeString = date.toLocaleTimeString(locale, Locale.ShortFormat)


        if ( date.getDate()  === now.getDate()  &&
        date.getMonth() === now.getMonth() &&
        date.getFullYear() === now.getFullYear() ) {
            return fullTimeString
        }

        var fullDateString =  date.toLocaleDateString(locale, Locale.ShortFormat)
        return fullDateString + i18n.tr(" - ") + fullTimeString
    }

}
