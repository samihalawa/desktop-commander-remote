# DC Remote — Desktop Commander Menubar App

[![Platform](https://img.shields.io/badge/platform-macOS%2012%2B-blue?logo=apple)](https://github.com/samihalawa/desktop-commander-remote/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/samihalawa/desktop-commander-remote?style=social)](https://github.com/samihalawa/desktop-commander-remote)
[![Download DMG](https://img.shields.io/badge/Download-DMG%20Installer-blue?logo=apple)](https://github.com/samihalawa/desktop-commander-remote/releases/latest)

**Remote control your Mac from anywhere using AI.** DC Remote is a native macOS menubar app that turns your Mac into a remote-accessible device for [Desktop Commander MCP](https://github.com/wonderwhy-er/DesktopCommanderMCP) — letting Claude, GPT-4, Gemini, and other AI agents control your desktop remotely via the MCP protocol.

![DC Remote MenuBar Screenshot](./header.png)

---

## What It Does

DC Remote installs a lightweight native menubar app + a background daemon that registers your Mac as a **remote device** on [mcp.desktopcommander.app](https://mcp.desktopcommander.app). Once running, any Claude Desktop session (or other MCP client) on any machine can connect and:

- **Run terminal commands** on your Mac remotely
- **Read and edit files** across your filesystem
- **Manage processes** — start, stop, monitor
- **Execute shell scripts** and automation workflows
- **Access your local dev environment** from a remote AI chat

---

## Features

- **Native macOS menubar app** — lives in your menu bar, zero Dock clutter
- **One-click start/stop** — toggle the remote daemon from the menubar
- **Dashboard window** — embedded web UI at `mcp.desktopcommander.app`
- **Live logs viewer** — see real-time connection and command logs
- **Device ID management** — copy your unique device ID for pairing
- **Auto-launch on login** via LaunchAgent (optional)
- **Signed with Developer ID** — no Gatekeeper warnings
- **Self-contained DMG installer** — drag-and-drop install, no dependencies

---

## Quick Install

### Option 1 — DMG (recommended)

1. Download the latest DMG from [Releases](https://github.com/samihalawa/desktop-commander-remote/releases/latest)
2. Open the DMG and drag **DC Remote MenuBar.app** to `/Applications`
3. Launch the app — it appears in your menu bar
4. Click the monitor icon → **Start** to activate the remote daemon

### Option 2 — npm (daemon only, no menubar UI)

```bash
npx @wonderwhy-er/desktop-commander setup
```

---

## Usage

### Start the remote device

Click the monitor icon in your menu bar → **Start**

The icon turns green when the daemon is online and your Mac is reachable.

### Connect from Claude Desktop

Add this to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "desktop-commander-remote": {
      "command": "npx",
      "args": ["-y", "@wonderwhy-er/desktop-commander"],
      "env": {
        "DEVICE_ID": "your-device-id-here"
      }
    }
  }
}
```

Get your **Device ID** from the menubar: click the monitor icon → **Copy Device ID**.

### Dashboard

Click **Dashboard** in the menubar to open the web UI at `mcp.desktopcommander.app` — see connected devices, live session logs, and settings.

---

## Architecture

```
┌─────────────────────────────────────────┐
│  macOS (your Mac)                        │
│                                         │
│  ┌────────────────┐   ┌───────────────┐ │
│  │ DCRemoteMenuBar│──▶│  Node daemon  │ │
│  │  (Swift .app)  │   │  device.js    │ │
│  └────────────────┘   └───────┬───────┘ │
│                               │ WebSocket│
└───────────────────────────────┼─────────┘
                                ▼
                ┌───────────────────────────┐
                │  mcp.desktopcommander.app  │
                │  (relay / MCP broker)      │
                └───────────────────────────┘
                                ▲
                                │ MCP protocol
                ┌───────────────────────────┐
                │  Claude Desktop / AI client│
                │  (any machine, anywhere)   │
                └───────────────────────────┘
```

The **menubar app** (Swift) manages the **Node.js daemon** (`dist/remote-device/device.js`) via `launchctl`. The daemon opens a persistent WebSocket to the relay server. AI clients connect to the relay and issue MCP tool calls that the daemon executes locally on your Mac.

---

## Build from Source

### Prerequisites

- macOS 12+
- Xcode Command Line Tools (`xcode-select --install`)
- Node.js 18+

### Build menubar app

```bash
git clone https://github.com/samihalawa/desktop-commander-remote
cd desktop-commander-remote

# Compile Swift menubar app
swiftc menubar/DCRemoteMenuBar.swift \
  -framework Cocoa -framework WebKit \
  -o /tmp/DCRemoteMenuBar.app/Contents/MacOS/DCRemoteMenuBar

# Build Node daemon
npm install && npm run build
```

### Build DMG

```bash
brew install create-dmg
create-dmg \
  --volname "DC Remote MenuBar" \
  --window-size 600 400 \
  --icon "DCRemoteMenuBar.app" 175 190 \
  --app-drop-link 425 190 \
  "DCRemoteMenuBar-1.0.0.dmg" \
  "/path/to/app/folder/"
```

---

## Remote Device Daemon

The daemon (`src/remote-device/device.ts`) is the core Node.js process:

- Connects to `mcp.desktopcommander.app` via WebSocket
- Authenticates with your unique device ID
- Exposes all Desktop Commander MCP tools remotely
- Handles reconnection, authentication, and command routing

```bash
# Run daemon directly (dev mode)
npm run device:start
```

---

## Contributing

PRs welcome. Please read [CONTRIBUTING.md](./.github/CONTRIBUTING.md) first.

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Commit changes: `git commit -m 'feat: add my feature'`
4. Push and open a PR

---

## FAQ

**Does this work with Claude Desktop?**
Yes. Add the MCP server config pointing to your device ID and you're done.

**Is my data secure?**
Commands are relayed via an encrypted WebSocket. Your device ID is the auth token — keep it private. See [SECURITY.md](./SECURITY.md) and [PRIVACY.md](./PRIVACY.md).

**Does the daemon run as a background service?**
Yes — it installs as a macOS LaunchAgent so it survives logout and auto-starts at login.

**Can I use this on Windows/Linux?**
The menubar app is macOS-only. The Node daemon (`device.js`) runs on any platform.

---

## License

MIT — see [LICENSE](./LICENSE)

---

<!-- SEO keywords: remote mac control, desktop commander mcp, macos remote access AI, MCP server mac, Claude Desktop remote, menubar app mac, AI terminal control, model context protocol remote, desktop automation AI, remote file editing mac, AI mac controller, mcp remote device, desktop commander remote daemon, mac AI agent -->
