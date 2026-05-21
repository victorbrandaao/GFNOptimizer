# GFN Booster (macOS)

![macOS](https://img.shields.io/badge/macOS-12.0+-000000?style=for-the-badge&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5.9+-FA7343?style=for-the-badge&logo=swift&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

A native, open-source macOS menu bar utility built in Swift, designed to eliminate ping spikes, stuttering, and optimize your system for stable GeForce NOW cloud gaming sessions. Perfect for competitive titles where every millisecond matters, like *League of Legends*, *Warzone*, or *Battlefield 6*.

![GFN Booster in Action](assets/preview.png)

## The Problem
Mac users relying on cloud gaming often experience random micro-stutters and sudden latency spikes, even on flawless fiber connections. In the Apple ecosystem, this is primarily caused by background routines:
1. **AWDL (Apple Wireless Direct Link):** The network interface managing AirDrop, Handoff, and AirPlay constantly scans for nearby devices. While unnoticeable during regular browsing, it completely ruins the strict latency required for game streaming.
2. **Location Services:** The system periodically scans Wi-Fi networks to update the Mac's location, causing network drops.
3. **Mouse Acceleration:** macOS forces a native pointer acceleration curve that ruins muscle memory and precision in FPS games or fast-paced clicking.
4. **Power & Backup Routines:** Time Machine performing heavy I/O network backups or the display dimming/sleeping while you use a controller.

## How it Works (Complete Transparency)
As an open-source project running system-level commands, transparency is key. When you click **"Enable GFN Booster"**, the app asks for Administrator privileges **only once** to group and execute the following optimizations:

* **Clean Network:** Temporarily disables the AWDL interface (`ifconfig awdl0 down`).
* **Direct Routing:** Flushes and rebuilds the system's DNS cache (`dscacheutil -flushcache; killall -HUP mDNSResponder`).
* **Raw Mouse Input:** Changes the mouse scaling factor to `-1` (`defaults write .GlobalPreferences com.apple.mouse.scaling -1`), ensuring raw input for precise aiming.
* **Bandwidth Focus:** Pauses Time Machine backups during the session (`tmutil disable`).
* **Console Mode (Anti-Sleep):** Starts the native `caffeinate` background process to prevent the display from sleeping or the CPU from throttling due to keyboard/mouse "inactivity" when playing with a controller.
* **Auto-Launch:** Automatically opens the official **GeForce NOW** application right after applying the optimizations.

### Fail-Safe (Security)
Whenever you click **"Disable GFN Booster"** or simply **"Quit"** the app, it automatically reverts absolutely every change. It restores the default mouse speed (`1.5`), reactivates AirDrop/Handoff (`ifconfig awdl0 up`), enables Time Machine, and hands power management back to macOS.

## Installation

### Option 1: Download the App (Recommended)
1. Go to the [Releases](../../releases) page.
2. Download the latest `GFN_Booster_v1.0.1.dmg` file.
3. Open the `.dmg` and drag the app to your Applications folder.

> **⚠️ Important: "App is damaged" error**
> Since this app is open-source and isn't signed with a paid Apple Developer certificate, macOS Gatekeeper tags it with quarantine attributes when downloaded via a browser. If you get an error saying the app is damaged and should be moved to the Trash, simply open your **Terminal** and run this command to clear the quarantine flag:
> ```bash
> xattr -cr /Applications/"GFN Booster.app"
> ```
> After that, you can open the app normally!

### Option 2: Build from Source
To compile and run from the source code directly via terminal:

```bash
# Clone the repository
git clone [https://github.com/your-username/GFNOptimizer.git](https://github.com/your-username/GFNOptimizer.git)
cd GFNOptimizer

# Build and run via Swift Package Manager
swift run
