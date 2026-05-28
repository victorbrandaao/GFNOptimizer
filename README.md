# CloudBoost

Native macOS optimization toolkit for cloud gaming.

CloudBoost is a lightweight menu bar app built in Swift to reduce micro-stutters, ping spikes, and input lag during cloud gaming sessions. It focuses on temporary, reversible system tuning instead of permanent background services or opaque cleaner-style behavior.

<p align="center">
  <img src="https://img.shields.io/github/v/release/victorbrandaao/CloudBoost?style=for-the-badge">
  <img src="https://img.shields.io/github/downloads/victorbrandaao/CloudBoost/total?style=for-the-badge">
  <img src="https://img.shields.io/github/license/victorbrandaao/CloudBoost?style=for-the-badge">
  <img src="https://img.shields.io/badge/macOS-Apple%20Silicon%20%26%20Intel-black?style=for-the-badge">
  <img src="https://img.shields.io/badge/Swift-Native%20macOS-orange?style=for-the-badge">
</p>

<p align="center">
  <img src="./assets/img1.png" alt="CloudBoost Screenshot"/>
</p>

## Download

Download the latest release from the [Releases page](https://github.com/victorbrandaao/CloudBoost/releases).

For CloudBoost 3.0.4, download **CloudBoost_v3.0.4.dmg**, open the disk image, and drag **CloudBoost.app** to `/Applications`.

> **Gatekeeper note:** Because CloudBoost is independently signed, macOS may show an "App is damaged" warning on first launch. To clear the quarantine flag, run:
>
> ```bash
> xattr -cr /Applications/"CloudBoost.app"
> ```

## Supported Platforms

| Platform | Availability |
|---|---|
| GeForce NOW | Free |
| Xbox Cloud Gaming (xCloud) | Free |
| Boosteroid | PRO |
| Moonlight | PRO |
| VoidLink Extreme | PRO |

## What CloudBoost Does

macOS background services can interfere with latency-sensitive video streaming. When you enable CloudBoost, the app applies temporary optimizations for the selected session and restores the system when the session ends.

Current optimization areas include:

| Area | Purpose |
|---|---|
| AWDL control | Temporarily disables `awdl0` to reduce AirDrop/Handoff Wi-Fi scanning spikes |
| AWDL Guard | Restores `awdl0` automatically if CloudBoost stops unexpectedly |
| Process priority | Raises priority for the active streaming client with `renice` |
| DNS refresh | Clears stale local DNS cache during session startup |
| Power focus | Uses `caffeinate` to avoid sleep and session throttling |
| Time Machine control | Pauses backup activity in selected presets |
| Kernel-aware TCP tuning | Competitive mode can tune Darwin TCP delayed ACK and restore it later |
| Mouse profiles | Applies session mouse profiles for low-latency input |

All changes are designed to be temporary and reversible.

## CloudBoost PRO

CloudBoost PRO unlocks advanced automation and observability features:

| Feature | Free | PRO |
|---|---:|---:|
| GeForce NOW and xCloud support | Yes | Yes |
| Manual Boost | Yes | Yes |
| AWDL Guard rollback protection | Yes | Yes |
| Balanced preset | Yes | Yes |
| Boosteroid, Moonlight, VoidLink Extreme | No | Yes |
| Auto-Detect platform switching | No | Yes |
| Competitive and Stream Quality presets | No | Yes |
| Keep Alive | No | Yes |
| Diagnostics export | No | Yes |
| Adaptive Intelligence | No | Yes |

Adaptive Intelligence monitors route type, latency, jitter, packet loss, thermal pressure, Low Power Mode, and common background interference to classify session health in real time.

To activate PRO, purchase a license on [Gumroad](https://victorbrandao0.gumroad.com/l/CloudBoost), then click any locked feature in CloudBoost and enter the license key.

## Features

- Native macOS menu bar app, built with Swift.
- Redesigned session monitor with CPU, ping, priority, network path, jitter, session health, and AWDL Guard status.
- One-click enable/disable flow with automatic restore.
- Presets for Balanced, Competitive, and Stream Quality behavior.
- Floating HUD with live session statistics.
- Auto-updater with minimum-version enforcement for critical releases.
- Local diagnostics and self-test tooling for development builds.

## Developer Smoke Test

You can validate the observability layer from Terminal without requesting administrator privileges or changing system settings:

```bash
swift build
.build/debug/CloudBoost --self-test
```

The command prints the current network path, interface type, latency, jitter, packet loss, thermal state, Low Power Mode state, background interference, AWDL Guard status, and the optimization assessment.

## Build From Source

Requirements:

- macOS 13+
- Xcode Command Line Tools
- Swift 5.9+

Build and run:

```bash
git clone https://github.com/victorbrandaao/CloudBoost.git
cd CloudBoost
swift build
swift run CloudBoost
```

Create a local release build:

```bash
scripts/release.sh 3.0.4
```

## Security And Transparency

CloudBoost does not collect personal data, install kernel extensions, permanently modify protected system files, or run hidden daemons. The app uses supported macOS command-line tools and native APIs, and session changes are designed to be restored when CloudBoost is disabled or quits.

## Roadmap

- More platform-specific tuning profiles.
- Better browser-session detection.
- Expanded Adaptive Intelligence recommendations.
- Optional advanced diagnostics panel.
- More cloud gaming platform integrations.

## Contributing

Contributions, suggestions, and bug reports are welcome. Please open an issue or pull request on GitHub.

## License

Licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
