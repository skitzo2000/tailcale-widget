import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: fullRoot

    property bool settingsExpanded: false

    readonly property bool isDark: Kirigami.Theme.textColor.hslLightness > 0.5

    Layout.preferredWidth: Kirigami.Units.gridUnit * 16
    Layout.minimumWidth: Kirigami.Units.gridUnit * 12
    Layout.maximumWidth: Kirigami.Units.gridUnit * 16
    Layout.preferredHeight: Kirigami.Units.gridUnit * 22

    function headerIcon() {
        var variant = isDark ? "breeze-dark" : "breeze-light"
        if (!root.tsConnected) return Qt.resolvedUrl("icons/offline-" + variant + ".svg")
        if (root.tsCurrentExitNode !== "") return Qt.resolvedUrl("icons/exit-node-" + variant + ".svg")
        return Qt.resolvedUrl("icons/online-" + variant + ".svg")
    }

    PlasmaExtras.PlasmoidHeading {
        id: heading
        anchors { top: parent.top; left: parent.left; right: parent.right }

        RowLayout {
            anchors.fill: parent

            Kirigami.Icon {
                source: fullRoot.headerIcon()
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents.Label {
                    text: "Tailscale"
                    font.bold: true
                    Layout.fillWidth: true
                }

                PlasmaComponents.Label {
                    text: root.tsConnected ? root.tsBackendState : "Disconnected"
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
                    Layout.fillWidth: true
                }
            }

            PlasmaComponents.Switch {
                checked: root.tsConnected
                onToggled: root.toggleConnection()
            }
        }
    }

    Flickable {
        id: flick
        anchors {
            top: heading.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        contentWidth: width
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainColumn
            width: flick.width
            spacing: 0

            // Self info
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                spacing: 2
                visible: root.tsConnected

                PlasmaComponents.Label {
                    text: root.tsHostname
                    font.bold: true
                    Layout.fillWidth: true
                }

                PlasmaComponents.Label {
                    text: root.tsIP
                    opacity: 0.7
                    Layout.fillWidth: true
                }

                PlasmaComponents.Label {
                    text: "Exit node: " + root.tsCurrentExitNode
                    opacity: 0.7
                    Layout.fillWidth: true
                    visible: root.tsCurrentExitNode !== ""
                }
            }

            Kirigami.Separator { Layout.fillWidth: true; visible: root.tsConnected }

            // Settings — collapsible
            PlasmaComponents.ItemDelegate {
                Layout.fillWidth: true
                visible: root.tsConnected
                onClicked: fullRoot.settingsExpanded = !fullRoot.settingsExpanded

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        source: "configure"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        opacity: 0.7
                    }

                    PlasmaComponents.Label {
                        text: "Settings"
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Kirigami.Icon {
                        source: fullRoot.settingsExpanded ? "arrow-up" : "arrow-down"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        opacity: 0.5
                    }
                }
            }

            // Settings toggles
            ColumnLayout {
                visible: fullRoot.settingsExpanded
                Layout.fillWidth: true
                spacing: 0

                SettingToggle {
                    label: "Accept Routes"
                    description: "Accept subnet routes from other nodes"
                    checked: root.tsAcceptRoutes
                    onToggled: root.setOption("accept-routes", checked)
                }

                SettingToggle {
                    label: "Accept DNS"
                    description: "Use Tailscale DNS settings"
                    checked: root.tsAcceptDNS
                    onToggled: root.setOption("accept-dns", checked)
                }

                SettingToggle {
                    label: "Shields Up"
                    description: "Block incoming connections"
                    checked: root.tsShieldsUp
                    onToggled: root.setOption("shields-up", checked)
                }

                SettingToggle {
                    label: "SSH Server"
                    description: "Allow Tailscale SSH access"
                    checked: root.tsRunSSH
                    onToggled: root.setOption("ssh", checked)
                }

                SettingToggle {
                    label: "Advertise Exit Node"
                    description: "Offer this device as an exit node"
                    checked: root.tsAdvertiseExitNode
                    onToggled: root.setOption("advertise-exit-node", checked)
                }

                SettingToggle {
                    label: "Allow LAN Access"
                    description: "Allow LAN access when using exit node"
                    checked: root.tsAllowLAN
                    onToggled: root.setOption("exit-node-allow-lan-access", checked)
                }
            }

            Kirigami.Separator { Layout.fillWidth: true; visible: root.tsConnected }

            // Devices header
            PlasmaComponents.Label {
                text: "Devices"
                font.bold: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                visible: root.tsConnected && root.tsDevices.count > 0
            }

            // Device list
            Repeater {
                model: root.tsDevices

                DeviceItem {
                    Layout.fillWidth: true
                    visible: root.tsConnected
                }
            }

            // Error: tailscale not found
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.gridUnit * 2
                Layout.margins: Kirigami.Units.gridUnit
                spacing: Kirigami.Units.smallSpacing
                visible: root.tsErrorState === "not-found"

                Kirigami.Icon {
                    source: "dialog-error"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                    Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                    Layout.alignment: Qt.AlignHCenter
                }

                PlasmaComponents.Label {
                    text: "Tailscale not found"
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                PlasmaComponents.Label {
                    text: "The tailscale command was not found. Make sure Tailscale is installed and in your PATH."
                    wrapMode: Text.WordWrap
                    opacity: 0.7
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                PlasmaComponents.Label {
                    text: "View setup instructions"
                    color: Kirigami.Theme.linkColor
                    Layout.alignment: Qt.AlignHCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally("https://github.com/skitzo2000/tailscale-widget#setup")
                    }
                }
            }

            // Error: access denied (operator mode not set)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.gridUnit * 2
                Layout.margins: Kirigami.Units.gridUnit
                spacing: Kirigami.Units.smallSpacing
                visible: root.tsErrorState === "access-denied"

                Kirigami.Icon {
                    source: "dialog-warning"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                    Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                    Layout.alignment: Qt.AlignHCenter
                }

                PlasmaComponents.Label {
                    text: "Access denied"
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                PlasmaComponents.Label {
                    text: "Tailscale requires operator mode to run without root. Run this command once to fix it:"
                    wrapMode: Text.WordWrap
                    opacity: 0.7
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                PlasmaComponents.Label {
                    text: "sudo tailscale up --operator=$USER"
                    font.family: "monospace"
                    Layout.alignment: Qt.AlignHCenter
                }

                PlasmaComponents.Label {
                    text: "View full setup guide"
                    color: Kirigami.Theme.linkColor
                    Layout.alignment: Qt.AlignHCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally("https://github.com/skitzo2000/tailscale-widget#setup")
                    }
                }
            }

            // Disconnected (no error, just turned off)
            PlasmaExtras.PlaceholderMessage {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.gridUnit * 4
                visible: !root.tsConnected && root.tsErrorState === ""
                text: "Tailscale is disconnected"
                explanation: "Toggle the switch above to connect"
                iconName: "network-vpn"
            }
        }
    }
}
