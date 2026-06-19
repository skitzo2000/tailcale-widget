import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: service

    property bool connected: false
    property string backendState: "Unknown"
    property string errorState: ""  // "not-found", "access-denied", or ""
    property string selfHostname: ""
    property string selfIP: ""
    property string selfDNSName: ""
    property string magicDNSSuffix: ""
    property string currentExitNode: ""
    property alias devices: deviceModel

    // Tailnet (account) switching
    property string currentTailnet: ""          // CurrentTailnet.Name from status
    property bool switchAccessDenied: false      // true when `switch --list` needs operator mode
    property bool switching: false               // true while a `tailscale switch` is in flight
    property alias tailnets: tailnetModel        // available accounts to switch to

    ListModel {
        id: deviceModel
    }

    ListModel {
        id: tailnetModel
    }

    // Prefs properties
    property bool acceptRoutes: false
    property bool acceptDNS: false
    property bool shieldsUp: false
    property bool runSSH: false
    property bool advertiseExitNode: false
    property bool allowLAN: false

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            var stdout = data["stdout"] || ""
            var stderr = data["stderr"] || ""
            var exitCode = data["exit code"]

            if (sourceName.indexOf("tailscale status --json") !== -1) {
                if (exitCode !== 0 || stderr) {
                    detectError(stderr, exitCode)
                } else {
                    errorState = ""
                }
                parseStatus(stdout)
            } else if (sourceName.indexOf("tailscale debug prefs") !== -1) {
                parsePrefs(stdout)
            } else if (sourceName.indexOf("tailscale switch --list") !== -1) {
                parseSwitchList(stdout, stderr, exitCode)
            } else if (sourceName.indexOf("tailscale switch ") !== -1) {
                // A `tailscale switch <id>` finished — refresh everything.
                switching = false
                pollAfterSet.restart()
            }

            disconnectSource(sourceName)
        }

        function run(cmd) {
            connectSource(cmd)
        }
    }

    // Run the full set of read commands that drive the UI.
    function refresh() {
        executable.run("tailscale status --json")
        executable.run("tailscale debug prefs")
        executable.run("tailscale switch --list")
    }

    Timer {
        id: pollTimer
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: service.refresh()
    }

    function detectError(stderr, exitCode) {
        var msg = stderr.toLowerCase()
        if (msg.indexOf("not found") !== -1 || msg.indexOf("no such file") !== -1) {
            errorState = "not-found"
        } else if (msg.indexOf("access denied") !== -1 || msg.indexOf("permission denied") !== -1) {
            errorState = "access-denied"
        } else if (exitCode !== 0 && !connected) {
            errorState = "access-denied"
        }
    }

    function parseStatus(stdout) {
        if (!stdout) {
            connected = false
            backendState = "Unknown"
            devices.clear()
            return
        }

        try {
            var json = JSON.parse(stdout)

            backendState = json.BackendState || "Unknown"
            connected = (backendState === "Running")

            if (json.Self) {
                selfHostname = json.Self.HostName || ""
                selfDNSName = (json.Self.DNSName || "").replace(/\.$/, "")
                if (json.Self.TailscaleIPs && json.Self.TailscaleIPs.length > 0) {
                    selfIP = json.Self.TailscaleIPs[0]
                } else {
                    selfIP = ""
                }
            }

            magicDNSSuffix = json.MagicDNSSuffix || ""

            if (json.CurrentTailnet) {
                currentTailnet = json.CurrentTailnet.Name || ""
            }

            // Build new peer list from JSON
            var newPeers = []
            var exitNodeHost = ""
            if (json.Peer) {
                var keys = Object.keys(json.Peer)
                for (var i = 0; i < keys.length; i++) {
                    var peer = json.Peer[keys[i]]
                    var ip = ""
                    if (peer.TailscaleIPs && peer.TailscaleIPs.length > 0) {
                        ip = peer.TailscaleIPs[0]
                    }
                    var dnsName = (peer.DNSName || "").replace(/\.$/, "")
                    var isExitNode = peer.ExitNode || false
                    if (isExitNode) {
                        exitNodeHost = peer.HostName || ""
                    }
                    newPeers.push({
                        hostName: peer.HostName || "",
                        tailscaleIP: ip,
                        online: peer.Online || false,
                        active: peer.Active || false,
                        dnsName: dnsName,
                        exitNodeOption: peer.ExitNodeOption || false,
                        isExitNode: isExitNode,
                        os: peer.OS || "",
                        expired: peer.Expired || false
                    })
                }
            }
            currentExitNode = exitNodeHost

            // Update model in-place to preserve delegate state
            updateDevices(newPeers)
        } catch (e) {
            console.warn("Tailscale: failed to parse status JSON:", e)
        }
    }

    function updateDevices(newPeers) {
        // Build lookup by hostName for existing items
        var existingByHost = {}
        for (var i = 0; i < devices.count; i++) {
            existingByHost[devices.get(i).hostName] = i
        }

        var newByHost = {}
        for (var j = 0; j < newPeers.length; j++) {
            newByHost[newPeers[j].hostName] = true
        }

        // Remove peers that no longer exist (iterate backwards)
        for (var r = devices.count - 1; r >= 0; r--) {
            if (!newByHost[devices.get(r).hostName]) {
                devices.remove(r)
            }
        }

        // Update existing or append new
        for (var k = 0; k < newPeers.length; k++) {
            var p = newPeers[k]
            // Re-scan since indices may have shifted
            var found = -1
            for (var m = 0; m < devices.count; m++) {
                if (devices.get(m).hostName === p.hostName) {
                    found = m
                    break
                }
            }
            if (found >= 0) {
                devices.set(found, p)
            } else {
                devices.append(p)
            }
        }
    }

    function parsePrefs(stdout) {
        if (!stdout) return
        try {
            var json = JSON.parse(stdout)
            acceptRoutes = json.RouteAll || false
            acceptDNS = json.CorpDNS || false
            shieldsUp = json.ShieldsUp || false
            runSSH = json.RunSSH || false
            allowLAN = json.ExitNodeAllowLANAccess || false

            var routes = json.AdvertiseRoutes || []
            advertiseExitNode = false
            for (var i = 0; i < routes.length; i++) {
                if (routes[i] === "0.0.0.0/0" || routes[i] === "::/0") {
                    advertiseExitNode = true
                    break
                }
            }
        } catch (e) {
            console.warn("Tailscale: failed to parse prefs JSON:", e)
        }
    }

    // Parse the columnar output of `tailscale switch --list`:
    //
    //   ID    Tailnet                  Account
    //   c9a9  goldfish.paul@gmail.com  goldfish.paul@gmail.com
    //   29cd  skerbetzdc@yahoo.com     goldfish.paul@gmail.com*
    //
    // The currently-active account is marked with a trailing "*".
    // Listing accounts requires operator mode; without it the command
    // fails with an "access denied" error.
    function parseSwitchList(stdout, stderr, exitCode) {
        var msg = (stderr || "").toLowerCase()
        if (exitCode !== 0 || msg.indexOf("access denied") !== -1) {
            switchAccessDenied = (msg.indexOf("access denied") !== -1 || msg.indexOf("denied") !== -1)
            tailnetModel.clear()
            return
        }
        switchAccessDenied = false

        var lines = (stdout || "").split("\n")
        tailnetModel.clear()
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line === "") continue
            // Skip the header row.
            if (line.indexOf("ID") === 0 && line.indexOf("Tailnet") !== -1) continue

            var isCurrent = line.charAt(line.length - 1) === "*"
            var clean = isCurrent ? line.slice(0, -1).trim() : line
            var fields = clean.split(/\s{2,}/)
            if (fields.length < 2) continue

            tailnetModel.append({
                accountId: fields[0],
                tailnet: fields[1],
                account: fields.length >= 3 ? fields[2] : fields[1],
                current: isCurrent
            })
        }
    }

    function switchTailnet(accountId) {
        if (!accountId || switching) return
        switching = true
        executable.run("tailscale switch " + accountId)
    }

    function setOption(flag, value) {
        var cmd
        if (typeof value === "boolean") {
            cmd = "tailscale set --" + flag + "=" + (value ? "true" : "false")
        } else {
            cmd = "tailscale set --" + flag + "=" + value
        }
        executable.run(cmd)
        pollAfterSet.restart()
    }

    Timer {
        id: pollAfterSet
        interval: 1000
        repeat: false
        onTriggered: service.refresh()
    }

    function toggleConnection() {
        if (connected) {
            executable.run("tailscale down")
        } else {
            executable.run("tailscale up")
        }
    }
}
