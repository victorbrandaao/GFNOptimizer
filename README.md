# CloudBoost

<p align="left">
  <img src="https://img.shields.io/badge/macOS-12.0+-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS" />
  <img src="https://img.shields.io/badge/Architecture-Universal_Binary-8A2BE2?style=for-the-badge" alt="Universal Binary" />
  <img src="https://img.shields.io/badge/Swift-5.9+-FA7343?style=for-the-badge&logo=swift&logoColor=white" alt="Swift" />
  <img src="https://img.shields.io/github/downloads/victorbrandaao/CloudBoost/total?style=for-the-badge&color=2ea44f&logo=github" alt="Total Downloads" />
</p>

CloudBoost is a native macOS menu bar utility designed to optimize your system in real-time, eliminating micro-stutters, ping spikes, and input lag during cloud gaming sessions.

Currently supports: **GeForce NOW**, **Boosteroid**, **Xbox Cloud Gaming (xCloud)**, **Moonlight**, and **VoidLink Extreme**.

<br>

<p align="center">
  <img src="assets/img1.png" width="400" alt="CloudBoost Default Menu">
  &nbsp;&nbsp;&nbsp;&nbsp;
</p>

<br>

---

## Installation

1. Go to the [Releases](https://github.com/victorbrandaao/CloudBoost/releases/latest) tab and download the latest **CloudBoost_v3.0.1.dmg** file.
2. Open the `.dmg` and drag **CloudBoost.app** to your `/Applications` folder.

> **Note on macOS Gatekeeper:**
> Because this is an independently signed tool, macOS might throw an "App is damaged" error on the first launch. To clear the quarantine flag, open Terminal and run:
> ```bash
> xattr -cr /Applications/"CloudBoost.app"
> ```

---

## CloudBoost PRO

The PRO version unlocks advanced optimization toggles.

1. Get a license on [Gumroad](https://victorbrandao0.gumroad.com/l/CloudBoost).
2. You will receive an email with your license key.
3. Open CloudBoost, click on any PRO feature, and paste the key to activate it locally.

---

## How it works

macOS runs background processes that can interfere with low-latency video streams. When activated, CloudBoost requests Administrator privileges (once per session) to handle the following system tweaks:

* **AWDL Off:** Disables the `awdl0` network interface (AirDrop/Handoff) to stop background Wi-Fi scanning, the main cause of sudden ping drops.
* **Process Priority (`renice`):** Identifies the active streaming client and forces a `-20` nice level priority to prevent background apps from stealing CPU cycles.
* **Mouse Profiles:** Toggle between FPS (Raw Input) and MOBA (Fast) profiles to bypass Apple's native mouse acceleration curve.
* **RAM & DNS:** Flushes the DNS cache for direct routing and purges inactive unified memory to free up physical RAM for the video decoder.
* **Power Focus:** Pauses Time Machine backups and runs `caffeinate` to prevent system throttling or sleep during a session.

**Fail-Safe:** Clicking "Disable CloudBoost" or quitting the app instantly reverts your system to its default state.

---

## Features

* **Native UI:** Programmatic dark-mode interface built for macOS.
* **Performance HUD:** Floating overlay showing live CPU usage, nice level, and ping stats.
* **Presets:** Choose between Competitive, Balanced, and Stream Quality.
* **Auto-Detect:** Automatically switches priority targeting based on the active platform.
* **Auto-Updater:** Enforces critical updates to maintain compatibility with cloud services.

---

## Support the Project

If this tool improves your setup, consider [sponsoring the project](https://github.com/sponsors/victorbrandaao). Sponsorships help cover maintenance, new platform integrations, and feature requests.
