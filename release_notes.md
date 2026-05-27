CloudBoost is a native macOS menu bar utility written in Swift, focused on optimizing macOS in real-time to reduce micro-stutters, ping spikes, and input lag during cloud gaming sessions.

### 🚀 What's New in 3.0.2 (FINAL)
* **License Validation Fix:** Fixed Gumroad API compatibility by transitioning to `product_id`.
* **macOS Monterey Support:** Fixed a compiler SDK linking issue. CloudBoost is now fully backwards compatible and officially supports macOS 12.0+ out of the box.
* **UI/UX Redesign:** Complete overhaul of the popover menu. Features a new centralized layout, modern card-based sections, and dedicated action buttons for a truly native Apple-like feel.
* **Security & Stability:** Hardened Keychain validation and modular architecture improvements for faster performance.

---

### 📥 Installation

1. Go to the **Assets** section below and download the latest **CloudBoost_v3.0.2.dmg** file.
2. Open the `.dmg` and drag **CloudBoost.app** to your `/Applications` folder.

> **⚠️ Note on macOS Gatekeeper:**
> Because this is an independently signed tool, macOS might throw an "App is damaged" error on the first launch. To clear the quarantine flag, open Terminal and run:
> ```bash
> xattr -cr /Applications/"CloudBoost.app"
> ```

---

### ⚠️ Important: Mandatory Update (Kill Switch)
This release enforces the execution of the latest version of the app via a kill switch mechanism, ensuring continuous compatibility with cloud platform updates and security fixes.

---

### ⚙️ Features and System Modifications

macOS runs background processes that can interfere with high refresh rate video decoders. CloudBoost automates the following system tweaks:

* **AWDL Off:** Temporarily disables the `awdl0` network interface (AirDrop/Handoff) to prevent background Wi-Fi scanning, the main cause of ping spikes.
* **Process Priority (`renice`):** Identifies the active streaming client (GeForce NOW, xCloud, Boosteroid, Moonlight, VoidLink) and forces a `-20` priority level on the CPU.
* **Mouse Profiles:** Toggle between FPS (Raw Input) and MOBA (Fast) profiles directly from the menu bar, bypassing the native macOS acceleration curve.
* **RAM & DNS:** Flushes the DNS cache to force direct routing and purges inactive unified memory, freeing up physical space for streaming.
* **Power Focus:** Pauses Time Machine backups and triggers `caffeinate` to prevent CPU throttling and screen sleep.
* **Fail-safe:** When disabling CloudBoost or quitting the app, all system settings are instantly reverted to their original defaults.

---

### 🔐 CloudBoost PRO Activation

To unlock advanced features (like Auto-Detect, Keep Alive, and Extreme Presets):

1. Get a license on [Gumroad](https://victorbrandao0.gumroad.com/l/CloudBoost).
2. The activation code will be sent to your email.
3. In CloudBoost, click on the **Buy PRO** button (or any locked feature) and enter the key to validate the license locally.

`[MIN_VERSION: 3.0.2]`
