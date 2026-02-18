# Tailscale Widget for KDE Plasma 6

A system tray widget for managing and monitoring [Tailscale](https://tailscale.com) from your KDE Plasma panel.

## Features

- **Tray icon** reflects connection state: online, offline, or exit node active
- **Quick toggle** to connect/disconnect Tailscale
- **Device list** showing all peers with online status and exit node badges
- **Expandable device details** — click any peer to reveal:
  - DNS name (clickable — opens in browser)
  - Tailscale IP (clickable — opens in browser)
  - OS info
  - "Use as exit node" checkbox for exit-capable peers
- **Collapsible settings panel** with toggles for:
  - Accept Routes
  - Accept DNS
  - Shields Up
  - SSH Server
  - Advertise Exit Node
  - Allow LAN Access
- **Theme-aware icons** — adapts to Breeze light/dark automatically
- **Error detection** — shows setup instructions if Tailscale isn't accessible

## Requirements

- KDE Plasma 6
- Tailscale installed and accessible via CLI (`tailscale` command in your PATH)
- Operator mode configured (see [Setup](#setup) below)

## Setup

This widget runs `tailscale` commands as your regular user. By default, the Tailscale daemon (`tailscaled`) only allows root to control it. You need to configure **operator mode** so your user can run commands without `sudo`.

### Step 1: Install Tailscale

Make sure Tailscale is installed and the daemon is running.

**Arch / CachyOS / NixOS:**

```bash
# Verify tailscale is installed
tailscale version

# Verify the daemon is running
systemctl status tailscaled
```

If `tailscaled` isn't running:

```bash
sudo systemctl enable --now tailscaled
```

### Step 2: Set operator mode

Run this **once** to grant your user permission to control Tailscale without root:

```bash
sudo tailscale up --operator=$USER
```

This tells the Tailscale daemon that your user is allowed to run `tailscale status`, `tailscale set`, `tailscale up`, `tailscale down`, etc. without `sudo`.

### Step 3: Verify it works

These commands should work **without** `sudo`:

```bash
tailscale status
tailscale status --json
tailscale debug prefs
```

If you see "access denied" errors, try:

```bash
# Restart the daemon after setting operator
sudo systemctl restart tailscaled

# Then set operator mode again
sudo tailscale up --operator=$USER
```

### NixOS-specific notes

On NixOS, you can set operator mode declaratively in your configuration:

```nix
services.tailscale = {
  enable = true;
  useRoutingFeatures = "both";  # if you need subnet routing or exit nodes
  extraUpFlags = [ "--operator=${username}" ];
};
```

Alternatively, if you manage Tailscale imperatively, run the `sudo tailscale up --operator=$USER` command after each daemon restart.

### Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Widget shows "Tailscale not found" | `tailscale` not in PATH | Install Tailscale, ensure binary is in PATH |
| Widget shows "Access denied" | Operator mode not set | Run `sudo tailscale up --operator=$USER` |
| Settings toggles don't work | Operator mode not set | Same as above |
| Status shows but toggle fails | Partial permissions | Restart `tailscaled` then re-set operator |

## Installation

### Symlink (development)

```bash
ln -s "$(pwd)/package" ~/.local/share/plasma/plasmoids/com.github.skitzo2000.tailscale-widget
```

### Manual copy

```bash
mkdir -p ~/.local/share/plasma/plasmoids/com.github.skitzo2000.tailscale-widget
cp -r package/* ~/.local/share/plasma/plasmoids/com.github.skitzo2000.tailscale-widget/
```

Then restart Plasma:

```bash
plasmashell --replace &
```

Add the widget to your panel: right-click panel → "Add Widgets" → search "Tailscale".

## Testing

Run in a standalone window without affecting your panel:

```bash
plasmawindowed com.github.skitzo2000.tailscale-widget
```

## Project Structure

```
package/
  metadata.json                  # Widget metadata (name, version, service type)
  contents/
    ui/
      main.qml                   # Entry point, property wiring
      CompactRepresentation.qml  # Tray icon
      FullRepresentation.qml     # Popup panel (self info, settings, device list)
      TailscaleService.qml       # CLI polling, JSON parsing, setOption()
      DeviceItem.qml             # Expandable peer row delegate
      SettingToggle.qml          # Reusable label + switch row
      icons/                     # SVG icons (online/offline/exit-node variants)
```

## How It Works

The widget polls `tailscale status --json` and `tailscale debug prefs` every 5 seconds to get peer data and current settings. Changes are applied via `tailscale set --flag=value`. The device model is updated in-place to preserve UI state (expanded rows stay expanded across polls).

If the CLI is missing or returns permission errors, the widget displays an error screen with the fix command and a link back to this documentation.

## Icon Credits

Tray and header icons from [KTailctl](https://github.com/f-koehler/KTailctl) by Fabian Koehler, licensed under GPL-3.0.

## License

GPL-3.0
