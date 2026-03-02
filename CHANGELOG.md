# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Server profile configuration dialog for defining multiple Tailscale/Headscale servers
- Automatic profile switching via widget header dropdown menu
- Active server detection via ControlURL from `tailscale debug prefs`
- Auth key support for automatic re-authentication when switching profiles
- Built-in "Tailscale" default profile that cannot be removed

### Changed
- Widget header now shows the active profile name instead of hardcoded "Tailscale"
- Tooltip shows profile name and hostname
- Subtitle shows switching state and errors during profile transitions
