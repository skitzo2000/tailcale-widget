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

    // Profile management
    property bool tsSwitching: tailscale.switching
    property string tsSwitchError: tailscale.switchError
    property var tsProfiles: []
    property string tsActiveProfileName: resolveActiveProfile()

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    toolTipMainText: tsActiveProfileName
    toolTipSubText: tsConnected ? tsActiveProfileName + " — " + tsHostname : "Disconnected"

    TailscaleService {
        id: tailscale
    }

    Connections {
        target: Plasmoid.configuration
        function onServerProfilesChanged() {
            root.parseProfiles()
        }
    }

    Component.onCompleted: parseProfiles()

    function toggleConnection() {
        tailscale.toggleConnection()
    }

    function setOption(flag, value) {
        tailscale.setOption(flag, value)
    }

    function parseProfiles() {
        try {
            tsProfiles = JSON.parse(Plasmoid.configuration.serverProfiles)
        } catch(e) {
            tsProfiles = [{"name": "Tailscale", "loginServerUrl": "", "authKey": ""}]
        }
        if (tsProfiles.length === 0) {
            tsProfiles = [{"name": "Tailscale", "loginServerUrl": "", "authKey": ""}]
        }
    }

    function resolveActiveProfile() {
        var url = tailscale.controlURL
        for (var i = 0; i < tsProfiles.length; i++) {
            var profileUrl = tsProfiles[i].loginServerUrl
            // Empty loginServerUrl matches official Tailscale
            if (profileUrl === "" && (url === "" || url === "https://controlplane.tailscale.com")) {
                return tsProfiles[i].name
            }
            if (profileUrl === url) {
                return tsProfiles[i].name
            }
        }
        if (tsProfiles.length > 0) {
            return tsProfiles[0].name  // fallback to first profile
        }
        return "Tailscale"
    }

    function switchProfile(index) {
        if (index < 0 || index >= tsProfiles.length) return
        var profile = tsProfiles[index]
        tailscale.switchProfile(profile.loginServerUrl, profile.authKey)
    }
}
