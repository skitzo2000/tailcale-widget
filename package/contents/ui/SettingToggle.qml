import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

RowLayout {
    id: toggle

    property string label: ""
    property string description: ""
    property alias checked: sw.checked
    signal toggled()

    spacing: Kirigami.Units.smallSpacing
    Layout.fillWidth: true

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        PlasmaComponents.Label {
            text: toggle.label
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        PlasmaComponents.Label {
            text: toggle.description
            opacity: 0.7
            Layout.fillWidth: true
            elide: Text.ElideRight
            visible: toggle.description !== ""
        }
    }

    PlasmaComponents.Switch {
        id: sw
        onToggled: toggle.toggled()
    }
}
