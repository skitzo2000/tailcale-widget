# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KDE Plasma panel widget (plasmoid) for managing and monitoring Tailscale. The widget provides quick access to Tailscale status, connected devices, and controls from the Plasma system tray.

## Tech Stack

- **UI**: QML (Qt Modeling Language) + JavaScript
- **Platform**: KDE Plasma 6
- **Integration**: Tailscale CLI (`tailscale`) and/or D-Bus

## Installation

The widget is installed directly as a plasmoid (no build step). The `package/` directory is the plasmoid package. Install via symlink or `kpackagetool6`.

To test the widget in a Plasma session after install:
```bash
plasmoidviewer -a <widget-id>
```

## Architecture

This is a standard KDE Plasma plasmoid. Key structural conventions:

- `package/metadata.json` — Widget metadata (name, version, KDE service type)
- `contents/ui/` — QML files defining the widget UI
- `contents/ui/main.qml` — Entry point for the widget
- `contents/config/` — Configuration schema (config.xml) and config UI (config.qml)

Tailscale interaction happens via subprocess calls to `tailscale status --json` or equivalent CLI commands. Parse JSON output for device list, connection status, exit node info, etc.
