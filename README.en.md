# Fresh Start

[简体中文](README.md) · [Download latest DMG](https://github.com/huangmlj/fresh-start/releases/latest)

Fresh Start is a small macOS utility that helps you return your workspace to a clean state before sleep, shutdown, or a fresh work session.

It lists running applications, lets you choose what should be closed, and can close selected apps with one click. It can also put your Mac to sleep after cleanup.

<p>
  <img src="assets/AppIcon.png" width="128" alt="Fresh Start app icon">
</p>

## Disclaimer

Fresh Start closes running applications. Before using one-click close or close-and-sleep, save important documents, uploads, downloads, terminal sessions, recordings, messages, and any other work that should not be interrupted.

Some apps may show their own save confirmation dialogs. If an app ignores a normal quit request, Fresh Start may use a stronger termination path for selected stubborn apps such as WeChat. Unsaved changes can be lost.

Use this app at your own discretion.

## Download

Download the latest `.dmg` from the GitHub Releases page:

[Download Fresh Start](https://github.com/huangmlj/fresh-start/releases/latest)

Open the DMG and drag `Fresh Start.app` into `Applications`.

## Features

- View currently running macOS apps in a clean table.
- Choose which apps are included in the close list.
- Right-click an app to mark it as “Do not quit by default”.
- Sort apps by name, status, memory usage, or PID.
- Show or hide system apps from Preferences.
- Close selected apps with one click.
- Close selected apps and put the Mac to sleep.
- Toggle macOS Low Power Mode with system administrator authorization.
- Fresh Start itself can be included in the close list and will quit last.

## How It Works

Fresh Start is intentionally conservative:

- Finder can be included in the close list like a regular app. If you do not want to close it, right-click it and mark it as “Do not quit by default”.
- System services are not killed blindly.
- Fresh Start focuses on user-facing apps and explicitly selected targets.
- If Fresh Start itself is selected, it waits until other selected apps are handled, then exits last.

## Notes

- Low Power Mode changes require macOS administrator authorization because they use `pmset`.
- If you cancel the authorization dialog, Fresh Start silently cancels that action.
- The app is currently distributed as a local/ad-hoc signed macOS app. Depending on your Gatekeeper settings, you may need to right-click and choose Open the first time.

## Support

If Fresh Start helps you, you can buy me a coffee:

<img src="assets/DonateQRCode.png" width="240" alt="Buy me a coffee QR code">

## Project

- Platform: macOS
- UI: SwiftUI + AppKit
- Build system: Swift Package Manager
- Distribution: DMG via GitHub Releases
