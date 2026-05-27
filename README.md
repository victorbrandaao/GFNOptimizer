# CloudBoost ☁️🚀

<p align="left">
  <img src="https://img.shields.io/badge/macOS-12.0+-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS" />
  <img src="https://img.shields.io/badge/Architecture-Universal_Binary-8A2BE2?style=for-the-badge" alt="Universal Binary" />
  <img src="https://img.shields.io/badge/Swift-5.9+-FA7343?style=for-the-badge&logo=swift&logoColor=white" alt="Swift" />
</p>

**CloudBoost** is a native macOS menu bar utility that optimizes your operating system in real-time to eliminate micro-stutters, ping spikes, and input lag during cloud gaming sessions.

Currently supports natively: **GeForce NOW**, **Boosteroid**, **Xbox Cloud Gaming (xCloud)**, **Moonlight**, and **VoidLink Extreme**.

<br>

<p align="center">
  <img src="assets/img1.png" width="400" alt="CloudBoost Default Menu">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/img2.png" width="400" alt="CloudBoost Feature Screenshot">
</p>

<br>

---

## 📥 Installation & Download

1. Go to the [Releases](https://github.com/victorbrandaao/CloudBoost/releases/latest) tab and download the latest **CloudBoost_v3.0.0.dmg** file.
2. Open the `.dmg` and drag **CloudBoost.app** to your `/Applications` folder.

> **⚠️ Important note on macOS Gatekeeper:**
> Because this is an independent tool, macOS will likely throw an "App is damaged" error when you try to open it for the first time. To clear the quarantine flag, simply open your Terminal and run:
> ```bash
> xattr -cr /Applications/"CloudBoost.app"
> ```

---

## 🔐 CloudBoost PRO

Unlock the full potential of your cloud gaming experience with **CloudBoost PRO**.

1. Purchase a license at [Gumroad](https://victorbrandao0.gumroad.com/l/CloudBoost).
2. You will receive an email with your unique license key.
3. Open CloudBoost on your Mac, click on any PRO feature, and paste the license key to activate.

---

## 🔍 How it works

macOS runs several background processes that compromise high-refresh-rate, low-latency video streams. When you enable CloudBoost, the app asks for Administrator privileges (just once per session) and automates the following tweaks:

* **Kills Ping Spikes (AWDL Off):** Temporarily disables the `awdl0` network interface (used for AirDrop and Handoff). This stops the constant background Wi-Fi scanning, which is the main culprit behind sudden ping drops.
* **Max CPU Priority (`renice`):** Identifies the process of your chosen platform and forces a maximum `-20` nice level priority, preventing background apps from stealing your CPU cycles and causing stream stutters.
* **Custom Mouse Profiles:** Lets you toggle between **FPS (Raw Input)** and **MOBA (Fast)** profiles directly from the menu bar, completely bypassing Apple's floaty native mouse acceleration curve.
* **RAM Purge & DNS Flush:** Flushes your DNS cache to ensure direct routing and forces a purge of inactive unified memory, freeing up physical RAM for the stream decoder.
* **Bandwidth & Power Focus:** Temporarily pauses Time Machine backups and triggers the native `caffeinate` command so your Mac doesn't throttle clock speeds or put the display to sleep mid-match.

**The Fail-Safe:** The moment you click "Disable CloudBoost" or quit the app, absolutely everything is instantly reverted to your system's default state.

---

## ✨ Features

* **Beautiful Popover UI:** A rich, programmatic dark-mode interface that fits perfectly natively on macOS.
* **Floating Performance HUD:** A sleek "pill" overlay that floats in the corner of your screen showing live CPU usage, nice level, and ping stats, automatically repositioning itself when monitors change.
* **Performance Presets:** Choose between *Competitive* (maximum boost), *Balanced* (network focus), and *Stream Quality* (disables RAM purging to avoid stream decoding micro-hitches).
* **Auto-Detect Platform:** CloudBoost can automatically detect which platform you are playing and switch its priority targeting.
* **Auto-Updater:** The app silently checks for updates and enforces mandatory critical updates to keep you on the most stable version.

---

## 💖 Support the Project

If CloudBoost improved your cloud gaming experience on macOS, please consider **[sponsoring the project](https://github.com/sponsors/victorbrandaao)**.

Your sponsorship directly helps fund:
* Ongoing maintenance and compatibility fixes.
* New platform integrations and requested features.
