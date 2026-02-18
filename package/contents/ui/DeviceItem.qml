import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: deviceDelegate

    property bool expanded: false

    spacing: 0

    // Compact row — click to toggle details
    PlasmaComponents.ItemDelegate {
        Layout.fillWidth: true
        onClicked: deviceDelegate.expanded = !deviceDelegate.expanded

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                width: Kirigami.Units.smallSpacing * 2
                height: width
                radius: width / 2
                color: model.online ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                Layout.alignment: Qt.AlignVCenter
            }

            PlasmaComponents.Label {
                text: model.hostName
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                visible: model.exitNodeOption
                width: exitLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                height: exitLabel.implicitHeight + 4
                radius: 3
                color: model.isExitNode ? Kirigami.Theme.positiveBackgroundColor : "transparent"
                border.color: model.isExitNode ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                border.width: 1

                PlasmaComponents.Label {
                    id: exitLabel
                    anchors.centerIn: parent
                    text: model.isExitNode ? "EXIT" : "exit"
                    font: Kirigami.Theme.smallFont
                    color: model.isExitNode ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                }
            }

            Kirigami.Icon {
                source: deviceDelegate.expanded ? "arrow-up" : "arrow-down"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                opacity: 0.5
            }
        }
    }

    // Detail panel
    Item {
        visible: deviceDelegate.expanded
        Layout.fillWidth: true
        implicitHeight: detailColumn.implicitHeight + Kirigami.Units.smallSpacing

        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) { mouse.accepted = true }
        }

        ColumnLayout {
            id: detailColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: Kirigami.Units.gridUnit
                rightMargin: Kirigami.Units.smallSpacing
            }
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: model.dnsName
                color: dnsMouseArea.containsMouse ? Kirigami.Theme.linkColor : Kirigami.Theme.textColor
                opacity: dnsMouseArea.containsMouse ? 1.0 : 0.7
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: model.dnsName !== ""

                MouseArea {
                    id: dnsMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: Qt.openUrlExternally("http://" + model.dnsName)
                }
            }

            PlasmaComponents.Label {
                text: model.tailscaleIP
                color: ipMouseArea.containsMouse ? Kirigami.Theme.linkColor : Kirigami.Theme.textColor
                opacity: ipMouseArea.containsMouse ? 1.0 : 0.7
                elide: Text.ElideRight
                Layout.fillWidth: true

                MouseArea {
                    id: ipMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: Qt.openUrlExternally("http://" + model.tailscaleIP)
                }
            }

            PlasmaComponents.Label {
                text: model.os
                font: Kirigami.Theme.smallFont
                opacity: 0.5
                visible: model.os !== ""
            }

            PlasmaComponents.CheckBox {
                visible: model.exitNodeOption
                text: "Use as exit node"
                checked: model.isExitNode
                onToggled: {
                    if (checked) {
                        root.setOption("exit-node", model.hostName)
                    } else {
                        root.setOption("exit-node", "")
                    }
                }
            }
        }
    }
}
