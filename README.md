<div align="center">
  <img src="lara/other/media.xcassets/AppIcon.appiconset/Eagle-Light.png" alt="Eagle app icon" width="152" height="152">

  # Eagle

  **Focused iOS personalization powered by DarkSword.**

  Customize wallpapers, passcode keys, Wallet card artwork, icons,
  Dynamic Island and Dock lighting from one app.

  [![Latest release](https://img.shields.io/github/v/release/leonardob8777-bit/Eagle?sort=semver&style=for-the-badge&label=LATEST%20RELEASE&color=7C3AED)](https://github.com/leonardob8777-bit/Eagle/releases)
  [![Total IPA downloads](https://img.shields.io/github/downloads/leonardob8777-bit/Eagle/total?style=for-the-badge&logo=icloud&logoColor=white&label=IPA%20DOWNLOADS&color=0891B2)](https://github.com/leonardob8777-bit/Eagle/releases)
  [![GitHub stars](https://img.shields.io/github/stars/leonardob8777-bit/Eagle?style=for-the-badge&logo=github&label=STARS&color=F59E0B)](https://github.com/leonardob8777-bit/Eagle/stargazers)
  [![AGPL-3.0](https://img.shields.io/github/license/leonardob8777-bit/Eagle?style=for-the-badge&label=LICENSE&color=16A34A)](LICENSE)

  <br>

  <a href="https://github.com/leonardob8777-bit/Eagle/releases/download/v1.0.0/Eagle.ipa">
    <img src="https://img.shields.io/badge/DOWNLOAD_EAGLE.IPA-VERSION_1.0.0-7C3AED?style=for-the-badge&logo=apple&logoColor=white" alt="Download Eagle 1.0.0 IPA" height="48">
  </a>

  <br><br>

  [Release notes](https://github.com/leonardob8777-bit/Eagle/releases/tag/v1.0.0)
  · [Report a bug](https://github.com/leonardob8777-bit/Eagle/issues/new?template=bug_report.md)
  · [Request a feature](https://github.com/leonardob8777-bit/Eagle/issues/new?template=feature_request.md)

  <sub>The release IPA is unsigned. Sign it with your usual personal-device installation method.</sub>
</div>

---

## At a glance

| | |
|---|---|
| **Current release** | Eagle 1.0.0 · build 59 |
| **Primarily verified on** | iPhone 16 Pro (`iPhone17,1`) · iOS 18.6.2 (`22G100`) |
| **Architecture** | `arm64e` |
| **Verified Aura surfaces** | Dynamic Island, Dock and current-page icon glow/outline · isolated apply and verification |
| **Project status** | Stable release · test one change at a time |

> [!WARNING]
> Eagle uses kernel-level and private SpringBoard capabilities. An incompatible
> operation can respring or reboot the device. Back up important data, test one
> change at a time and do not treat this as a production-safe utility.

## What Eagle includes

| Experience | What it does |
|---|---|
| 🎨 **Styles** | Coordinates wallpaper, passcode and Wallet-card experiences. |
| 🌌 **Wallpapers** | Browses community packs, imports compatible packages and converts short videos for Pocket Poster. |
| 💳 **Cards** | Previews, applies, backs up and restores supported Wallet card artwork. |
| 🔢 **Passcode** | Browses, imports, previews, applies and restores compatible key themes. |
| 🧩 **Icon Studio · Coming soon** | Temporarily unavailable while theme importing and custom shapes are validated. |
| 📱 **Dock** | Provides layouts supporting up to six apps where SpringBoard accepts them. |
| ✨ **Aura Studio** | Applies independently colored Dynamic Island and Dock lighting. Glow, Pulse and Island Rainbow remain available where compatible; Tint is temporarily unavailable. |
| 🔤 **App Name Color · Advanced** | Applies a page-owned solid color to app names on the current Home Screen page. |
| 🛡️ **Eagle System** | Adds Guardian checks, Scenes and shareable personalization recipes. |

### New in Eagle 1.0.0

- **Home Icon Neon** now offers both a diffuse glow and a precise neon outline around visible icons on the current Home page.
- **App Name Color** applies a solid custom color to the app names on the current page and keeps its overlays owned by that page to prevent migration when swiping.
- Aura Studio and App Name Color carry temporary one-time **NEW** badges. The Aura Studio Home card presents Dynamic Island clearly while Dock remains available inside.
- The **Updates** screen explains the current device status, supported iOS ranges, important exclusions and changes before use.
- Prepare progress, blocking-operation spinners and the Eagle icon use a restrained moving rainbow accent.
- Prepare validates device, build, cache and session state before reporting readiness, while result messages avoid false **Applied** states.
- Icon Studio is marked **Coming soon**, and Aura Tint is temporarily unavailable while Glow, Pulse and Island Rainbow remain available where compatible.
- Production now blocks Prepare on iPhone 16 (`iPhone17,3`) with iOS 18.5 after field reports of full device restarts.
- App Library Neon and Battery X remain excluded because they did not meet Eagle's visible-verification standard.

### Aura Studio safety model

- Dynamic Island and Dock are isolated operations: one surface is never marked
  active merely because the other succeeded.
- Rainbow is available for Dynamic Island. Dock Rainbow remains disabled because
  it has not been proven reliable on a physical device.
- Home Icon Neon is initially allowlisted for iPhone 16 Pro (`iPhone17,1`) on
  iOS 18.6.2 (`22G100`) and applies a one-time snapshot page by page.
- A failed verification keeps the safety lock closed and does not trigger an
  automatic respring.
- Aura overlays may disappear after a SpringBoard respring or device reboot and
  must then be applied again.

## Install Eagle

1. Use the large **Download Eagle.ipa** button at the top of this page.
2. Sign the unsigned IPA with your preferred personal-device sideloading method.
3. Install it and open Eagle manually from the Home Screen.
4. If you installed through Xcode, press **Stop** before preparing Eagle access.
5. Apply one feature at a time and keep the exact result message if something fails.

Looking for an older build? Browse [all Eagle releases](https://github.com/leonardob8777-bit/Eagle/releases).

## Compatibility and current limits

- **Prepare support:** iOS 16.x has limited testing (16.7.2 is the verified limited route);
  iOS 17.0–18.7.1 and 26.0–26.0.1 are accepted.
- iOS 18.7.2+, iOS 19–25, iOS 26.0.2+ and current MIE devices are blocked.
- Prepare is additionally blocked on iPhone 16 (`iPhone17,3`) running iOS 18.5
  because that hardware/release combination produced repeated field restarts.
- Aura Studio live changes remain limited to verified iOS 17/18 SpringBoard routes.
- If Island Aura reports **Safe Compact Halo**, it will not expand with music,
  screen recording or timers. Only **Adaptive Aura** follows those layouts.
- Screen, Battery Halo and Lock experiments are hidden while their live
  SpringBoard hosts remain unverified.
- Dock Aura is tuned primarily from iPhone 16 Pro testing and may need adjustment
  on other screen sizes.
- Icon importing, nonstandard masks and community packages remain dependent on
  device, iOS version and package structure.
- Kernel or SpringBoard operations are intentionally blocked while the Xcode
  debugger is attached.

Device strings such as `iPhone15,2` are Apple's technical model identifiers
(`iPhone15,2` is an iPhone 14 Pro), not the marketing generation number.

## Build from source

Requirements:

- macOS with Xcode
- `ldid` for packaging an unsigned IPA (`brew install ldid`)

Compile without installing on a device:

```sh
xcodebuild -project lara.xcodeproj \
  -scheme lara \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO build
```

Package the release IPA:

```sh
./scripts/build_ipa.sh
```

The result is written to `build/Eagle.ipa`.

## Report a problem

Open the [guided bug report](https://github.com/leonardob8777-bit/Eagle/issues/new?template=bug_report.md)
and include:

- exact iPhone or iPad model;
- iOS version and build number;
- Eagle version or commit;
- feature and selected mode;
- exact result message;
- the shareable Prepare or Aura diagnostic report when Eagle offers one;
- a full-width screenshot when the problem is visual;
- the relevant end of `Documents/lara.log`, with personal paths removed.

Do not publish tokens, certificates, provisioning profiles or unrelated personal files.

## Project lineage, license and acknowledgements

Eagle is a modified version of [Lara](https://github.com/rooootdev/lara). The
Eagle interface and feature set began diverging from Lara in August 2026.

Eagle is licensed as a whole under [GNU AGPL-3.0](LICENSE), preserving Lara's
license and notices. Source distributions and modified builds must continue to
comply with that license.

Core acknowledgements include the Lara contributors, rooootdev, opa334, ChOma,
XPF, AlfieCG/libgrabkernel2, DarkSword contributors, AppInstaller iOS and the
upstream projects whose notices remain in [`lara/licenses`](lara/licenses).
See Lara's [contributor history](https://github.com/rooootdev/lara/graphs/contributors)
for the complete upstream record.

---

<div align="center">
  <strong>Eagle</strong> · precise customization, explicit verification
  <br>
  <sub>Built with Swift, SwiftUI and DarkSword.</sub>
</div>
