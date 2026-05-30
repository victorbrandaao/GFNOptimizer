CloudBoost 3.1.0 is the first stable release of the new Mac gaming build. It expands CloudBoost beyond cloud gaming while making the core platform profiles free.

### What's New in 3.1.0

* **Cloud and Mac gaming profiles are now free:** GeForce NOW, Xbox Cloud Gaming, Boosteroid, Moonlight, VoidLink Extreme, Local Game, Steam, Epic Games, and Battle.net are available in the free version.
* **PRO is now focused on add-ons:** Auto-Detect, Auto Boost, Smart Boost, Stability Guard, Heat Guard, Keep Alive, diagnostics export, and advanced presets remain part of CloudBoost PRO.
* **Cleaner activation flow:** Missing platform apps no longer block the boost flow. CloudBoost can still apply the session profile even when a selected launcher is not installed.
* **Better session monitor:** Network path detection now has a fallback so the app does not incorrectly mark a healthy connection as offline.
* **Updated UI:** Platform cards are more compact and clearly separate Cloud Gaming and Mac Gaming as free core profiles.
* **Direct updater:** The in-app updater continues to check GitHub releases, download the DMG, and open the installer.

### Installation

1. Download **CloudBoost_v3.1.0.dmg** from the Assets section.
2. Open the DMG and drag **CloudBoost.app** to `/Applications`.

If macOS shows an "App is damaged" warning on first launch, clear the quarantine flag:

```bash
xattr -cr /Applications/"CloudBoost.app"
```

### Free vs PRO

The free version includes all supported cloud and Mac gaming profiles, manual boost, Balanced preset, AWDL Guard rollback protection, and basic system optimization.

CloudBoost PRO unlocks automation and advanced add-ons: Auto-Detect, Auto Boost, Smart Boost, Stability Guard, Heat Guard, Keep Alive, diagnostics export, and advanced presets.

Existing PRO customers keep access to every PRO feature they already purchased.

### System Modifications

CloudBoost may request administrator privileges during a session to apply supported macOS system changes:

* Temporarily control AWDL (`awdl0`) to reduce Wi-Fi scanning spikes.
* Flush DNS cache for cleaner routing.
* Increase selected game or streaming client process priority with `renice`.
* Pause Time Machine activity in selected presets.
* Run `caffeinate` to prevent sleep and throttling.
* Apply TCP delayed ACK tuning in advanced presets.

All session changes are designed to be reverted when CloudBoost is disabled or when the app quits.
