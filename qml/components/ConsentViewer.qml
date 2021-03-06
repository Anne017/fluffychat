import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Web 0.2

BottomEdge {

    id: consentViewer
    height: parent.height

    onCollapseCompleted: {
        consentUrl = ""
        consentContent = ""
        consentViewer.destroy ()
    }
    Component.onCompleted: commit()

    contentComponent: Page {
        height: consentViewer.height

        FcPageHeader {
            id: userHeader
            title: i18n.tr("Consent not given")
        }

        WebView {
            id: webview
            url: consentUrl
            width: parent.width
            height: parent.height - userHeader.height
            anchors.top: userHeader.bottom
        }
    }
}
