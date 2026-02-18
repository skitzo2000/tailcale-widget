import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    property bool tsConnected: tailscale.connected
    property string tsBackendState: tailscale.backendState
    property string tsErrorState: tailscale.errorState
    property var tsDevices: tailscale.devices
    property string tsHostname: tailscale.selfHostname
    property string tsIP: tailscale.selfIP
    property string tsSelfDNSName: tailscale.selfDNSName
    property string tsCurrentExitNode: tailscale.currentExitNode

    // Settings booleans
    property bool tsAcceptRoutes: tailscale.acceptRoutes
    property bool tsAcceptDNS: tailscale.acceptDNS
    property bool tsShieldsUp: tailscale.shieldsUp
    property bool tsRunSSH: tailscale.runSSH
    property bool tsAdvertiseExitNode: tailscale.advertiseExitNode
    property bool tsAllowLAN: tailscale.allowLAN

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    toolTipMainText: "Tailscale"
    toolTipSubText: tsConnected ? "Connected — " + tsHostname : "Disconnected"

    TailscaleService {
        id: tailscale
    }

    function toggleConnection() {
        tailscale.toggleConnection()
    }

    function setOption(flag, value) {
        tailscale.setOption(flag, value)
    }
}
