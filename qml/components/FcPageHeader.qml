import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3

PageHeader {
    id: header
    title: i18n.tr('FluffyChat')

    StyleHints {
        foregroundColor: settings.mainColor
    }

    extension: ProgressBar {
        id: requestProgressBar
        indeterminate: true
        width: parent.width
        anchors.bottom: parent.bottom
        visible: progressBarRequests > 0
    }
}
