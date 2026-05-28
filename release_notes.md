CloudBoost is a native macOS menu bar utility written in Swift, focused on reducing micro-stutters, ping spikes, and input lag during cloud gaming sessions.

### What's New in 3.0.4

This release is a major reliability and usability update focused on session stability, safer system-level networking, and clearer PRO value.

* **AWDL Guard:** CloudBoost now protects the `awdl0` optimization with a heartbeat-based fail-safe. If CloudBoost stops unexpectedly while AWDL is disabled, the guard restores `awdl0` to its original state automatically.
* **Adaptive Intelligence:** PRO users now get a real-time session assessment layer that monitors route type, latency, jitter, packet loss, thermal pressure, Low Power Mode, and common background interference.
* **Session Monitor UI:** The menu bar popover has been redesigned around a cleaner session dashboard with CPU, ping, process priority, network path, jitter, health, and AWDL guard status.
* **Kernel-aware network tuning:** Competitive mode can apply Darwin TCP delayed ACK tuning during active sessions and restore the previous value when CloudBoost is disabled.
* **Safer observability:** Network sampling now has timeout protection so a stuck ping command cannot freeze the session metrics or local self-test.
* **PRO packaging improvements:** The PRO plan now has clearer value: additional platforms, Auto-Detect, Keep Alive, Extreme Presets, diagnostics export, and Adaptive Intelligence.
* **Local self-test:** Developers can validate the observability layer with `.build/debug/CloudBoost --self-test` without requiring administrator privileges or modifying system settings.

### Installation

1. Go to the **Assets** section below and download **CloudBoost_v3.0.4.dmg**.
2. Open the `.dmg` and drag **CloudBoost.app** to your `/Applications` folder.

> **Note on macOS Gatekeeper:**
> Because this is an independently signed tool, macOS might show an "App is damaged" warning on first launch. To clear the quarantine flag, open Terminal and run:
> ```bash
> xattr -cr /Applications/"CloudBoost.app"
> ```

### CloudBoost PRO

CloudBoost PRO unlocks advanced automation and observability features:

* Additional platform support for Boosteroid, Moonlight, and VoidLink Extreme.
* Auto-Detect for active cloud gaming platforms.
* Keep Alive to prevent idle sleep during longer sessions.
* Competitive and Stream Quality presets.
* Diagnostics export for troubleshooting.
* Adaptive Intelligence with route, jitter, packet-loss, thermal, and interference scoring.

To activate PRO, purchase a license on [Gumroad](https://victorbrandao0.gumroad.com/l/CloudBoost), then enter the license key inside CloudBoost by clicking any locked feature.

### System Modifications

CloudBoost may request administrator privileges during a session to apply supported macOS system changes:

* Temporarily disable AWDL (`awdl0`) to reduce Wi-Fi scanning spikes.
* Flush DNS cache for cleaner routing.
* Increase streaming client process priority with `renice`.
* Pause Time Machine activity in selected presets.
* Run `caffeinate` to prevent sleep and throttling.
* Apply TCP delayed ACK tuning in Competitive mode.

All session changes are designed to be reverted when CloudBoost is disabled or when the app quits.

`[MIN_VERSION: 3.0.4]`
