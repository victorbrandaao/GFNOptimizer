<div align="center">

# CloudBoost

### Native macOS optimization toolkit for Cloud Gaming

Reduce interruptions, stabilize latency and prepare your Mac for smoother cloud gaming sessions with a lightweight native menu bar app.

<p align="center">
  <img src="https://img.shields.io/github/v/release/victorbrandaao/CloudBoost?style=for-the-badge">
  <img src="https://img.shields.io/github/downloads/victorbrandaao/CloudBoost/total?style=for-the-badge">
  <img src="https://img.shields.io/github/license/victorbrandaao/CloudBoost?style=for-the-badge">
  <img src="https://img.shields.io/badge/macOS-Apple%20Silicon%20%26%20Intel-black?style=for-the-badge">
  <img src="https://img.shields.io/badge/Swift-Native%20macOS-orange?style=for-the-badge">
</p>

<p align="center">
  <a href="https://github.com/victorbrandaao/CloudBoost/releases">
    <img src="https://img.shields.io/badge/Download-Latest%20Release-2ea44f?style=for-the-badge">
  </a>
</p>

</div>

---

<p align="center">
  <img src="./assets/img1.png" alt="CloudBoost Screenshot"/>
</p>

---

## What is CloudBoost?

CloudBoost is a native macOS utility designed to optimize your system for Cloud Gaming platforms like GeForce NOW, Xbox Cloud Gaming and Boosteroid.

Instead of manually tweaking macOS before every session, CloudBoost automatically applies temporary optimizations focused on:

- Lower latency
- Reduced background interference
- Better session consistency
- Improved responsiveness
- Fewer gameplay interruptions

Built entirely with Swift and native Apple frameworks.

---

## Supported Platforms

| Platform | Status |
|---|---|
| NVIDIA GeForce NOW | Supported |
| Xbox Cloud Gaming (xCloud) | Supported |
| Boosteroid | Supported |
| Amazon Luna | Planned |
| Shadow PC | Planned |
| Moonlight | Planned |
| Steam Remote Play | Planned |

---

## Features

### One-Click Optimization
Instantly optimize your Mac directly from the menu bar.

### Native macOS Application
Built with Swift using native APIs and system integrations.

### Automatic Restore
CloudBoost safely restores modified settings when optimization is disabled.

### Lightweight
No Electron. No unnecessary background services. No bloat.

### Menu Bar Integration
Fast access with a clean and minimal UI.

### Apple Silicon & Intel Support
Compatible with both Apple Silicon and Intel Macs.

### Open Source
Every optimization routine is visible and inspectable.

---

## How It Works

CloudBoost temporarily applies system-level optimizations during your gaming sessions to reduce interruptions and improve stability.

Some examples include:

| Optimization | Purpose |
|---|---|
| Sleep prevention | Prevent gameplay interruptions |
| DNS cache refresh | Reduce stale routing/cache behavior |
| Background activity reduction | Improve consistency |
| Session-focused system tuning | Reduce responsiveness spikes |

All optimizations are temporary and designed to be reversible.

---

## Installation

### Option 1 — Download Release

Download the latest `.dmg` from the Releases page:

👉 https://github.com/victorbrandaao/CloudBoost/releases

### Option 2 — Build From Source

#### Requirements

- macOS 13+
- Xcode 15+
- Swift 5.9+

#### Clone Repository

```bash
git clone https://github.com/victorbrandaao/CloudBoost.git
cd CloudBoost
```

#### Open Project

```bash
open CloudBoost.xcodeproj
```

Then build and run using Xcode.

---

## Security & Transparency

CloudBoost was designed with transparency in mind.

### CloudBoost does not:

- Collect personal data
- Send telemetry
- Install kernel extensions
- Permanently modify protected system files
- Run hidden daemons or spyware

### System Actions Currently Used

| Action | Why |
|---|---|
| `caffeinate` | Prevent system sleep during gameplay |
| DNS cache refresh | Reduce stale network behavior |
| Background process handling | Improve session consistency |
| Temporary optimization routines | Improve responsiveness |

All changes are temporary and reverted after optimization is disabled.

You can inspect the full source code at any time.

---

## Benchmarks & Results

> Results vary depending on hardware, network quality and cloud gaming platform.

Initial testing demonstrated improvements in:

- Reduced latency spikes
- Improved frame pacing consistency
- Fewer long-session interruptions
- Better responsiveness during gameplay

Future benchmark versions will include:

- Ping variance analysis
- Jitter monitoring
- Network diagnostics
- Stability scoring
- Session analytics

---

## Roadmap

- [ ] Optimization profiles
- [ ] Adaptive optimization engine
- [ ] Automatic session detection
- [ ] Advanced diagnostics panel
- [ ] Real-time network monitoring
- [ ] Platform-specific tuning presets
- [ ] Enhanced rollback safety system
- [ ] Expanded cloud gaming support

---

## Contributing

Contributions, suggestions and bug reports are welcome.

### How to Contribute

1. Fork the repository
2. Create a feature branch

```bash
git checkout -b feature/my-feature
```

3. Commit your changes

```bash
git commit -m "Add new feature"
```

4. Push your branch

```bash
git push origin feature/my-feature
```

5. Open a Pull Request

---

## License

Licensed under the MIT License.

See the [LICENSE](LICENSE) file for more information.
