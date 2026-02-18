import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

MouseArea {
    id: compactRoot

    readonly property bool connected: root.tsConnected
    readonly property bool isDark: Kirigami.Theme.textColor.hslLightness > 0.5
    readonly property bool exitActive: root.tsCurrentExitNode !== ""

    function iconPath() {
        var variant = isDark ? "breeze-dark" : "breeze-light"
        if (!connected) return Qt.resolvedUrl("icons/offline-" + variant + ".svg")
        if (exitActive) return Qt.resolvedUrl("icons/exit-node-" + variant + ".svg")
        return Qt.resolvedUrl("icons/online-" + variant + ".svg")
    }

    hoverEnabled: true
    onClicked: root.expanded = !root.expanded

    Kirigami.Icon {
        anchors.fill: parent
        source: compactRoot.iconPath()
        active: compactRoot.containsMouse
    }
}
