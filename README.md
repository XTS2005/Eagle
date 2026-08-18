<div align="center">
  <img src="lara/other/media.xcassets/AppIcon.appiconset/Eagle-Light.png" alt="Eagle app icon" width="152" height="152">

  # Eagle

  **Focused iOS personalization powered by DarkSword.**

  Customize wallpapers, passcode keys, Wallet card artwork, icons,
  Dynamic Island and Dock lighting from one app.

  [![Public beta](https://img.shields.io/github/v/release/leonardob8777-bit/Eagle?include_prereleases&sort=semver&style=for-the-badge&label=PUBLIC%20BETA&color=7C3AED)](https://github.com/leonardob8777-bit/Eagle/releases)
  [![Total IPA downloads](https://img.shields.io/github/downloads/leonardob8777-bit/Eagle/total?style=for-the-badge&logo=icloud&logoColor=white&label=IPA%20DOWNLOADS&color=0891B2)](https://github.com/leonardob8777-bit/Eagle/releases)
  [![GitHub stars](https://img.shields.io/github/stars/leonardob8777-bit/Eagle?style=for-the-badge&logo=github&label=STARS&color=F59E0B)](https://github.com/leonardob8777-bit/Eagle/stargazers)
  [![AGPL-3.0](https://img.shields.io/github/license/leonardob8777-bit/Eagle?style=for-the-badge&label=LICENSE&color=16A34A)](LICENSE)

  <br>

  <a href="https://github.com/leonardob8777-bit/Eagle/releases/download/v0.3.0-beta.8/Eagle.ipa">
    <img src="https://img.shields.io/badge/DOWNLOAD_EAGLE.IPA-PUBLIC_BETA_8-06B6D4?style=for-the-badge&logo=apple&logoColor=white" alt="Download the Eagle Public Beta 8 IPA" height="48">
  </a>

  <br><br>

  [Release notes](https://github.com/leonardob8777-bit/Eagle/releases/tag/v0.3.0-beta.8)
  · [Report a bug](https://github.com/leonardob8777-bit/Eagle/issues/new?template=bug_report.md)
  · [Request a feature](https://github.com/leonardob8777-bit/Eagle/issues/new?template=feature_request.md)

  <sub>The release IPA is unsigned. Sign it with your usual personal-device installation method.</sub>
</div>

---

## At a glance

| | |
|---|---|
| **Current release** | Eagle 0.3.0 Public Beta 8 · build 35 |
| **Primarily verified on** | iPhone 16 Pro (`iPhone17,1`) · iOS 18.6.2 (`22G100`) |
| **Architecture** | `arm64e` |
| **Verified Aura surfaces** | Dynamic Island and Dock · isolated apply and verification |
| **Project status** | Public beta · test one change at a time |

> [!WARNING]
> Eagle uses kernel-level and private SpringBoard capabilities. An incompatible
> operation can respring or reboot the device. Back up important data, test one
> change at a time and do not treat this beta as a production-safe utility.

## What Eagle includes

| Experience | What it does |
|---|---|
| 🎨 **Styles** | Coordinates wallpaper, passcode and Wallet-card experiences. |
| 🌌 **Wallpapers** | Browses community packs, imports compatible packages and converts short videos for Pocket Poster. |
| 💳 **Cards** | Previews, applies, backs up and restores supported Wallet card artwork. |
| 🔢 **Passcode** | Browses, imports, previews, applies and restores compatible key themes. |
| 🧩 **Icon Studio · Beta** | Imports icon themes and offers alternate icon shapes. |
| 📱 **Dock · Beta** | Provides layouts supporting up to six apps where SpringBoard accepts them. |
| ✨ **Aura Studio · Experimental** | Applies independently colored Dynamic Island and Dock lighting with Glow, Pulse, Island Rainbow, guarded Tint and per-surface verification. |
| 🛡️ **Eagle System** | Adds Guardian checks, Scenes and shareable personalization recipes. |

### New in Beta 8

- Faster navigation with local tool search and clearer Home organization.
- Favorites for wallpapers and passcode themes, plus remembered wallpaper choices.
- Search and responsive layouts for Font Library and Icon Studio, including safe removal of Eagle's local imported-font copies.
- Truthful OTA and Screen Time configuration readback, a live log viewer and a shareable support snapshot.
- Better layouts for Display Zoom, Dynamic Type and VoiceOver without changing the restored Dock or Dynamic Island Aura engine.

### Aura Studio safety model

- Dynamic Island and Dock are isolated operations: one surface is never marked
  active merely because the other succeeded.
- Rainbow is available for Dynamic Island. Dock Rainbow remains disabled because
  it has not been proven reliable on a physical device.
- A failed verification keeps the safety lock closed and does not trigger an
  automatic respring.
- Aura overlays may disappear after a SpringBoard respring or device reboot and
  must then be applied again.

## Install the public beta

1. Use the large **Download Eagle.ipa** button at the top of this page.
2. Sign the unsigned IPA with your preferred personal-device sideloading method.
3. Install it and open Eagle manually from the Home Screen.
4. If you installed through Xcode, press **Stop** before preparing Eagle access.
5. Apply one feature at a time and keep the exact result message if something fails.

Looking for an older build? Browse [all Eagle releases](https://github.com/leonardob8777-bit/Eagle/releases).

## Compatibility and current limits

- **Prepare support:** iOS 16.x is experimental (16.7.2 has limited testing);
  iOS 17.0–18.7.1 and 26.0–26.0.1 are accepted.
- iOS 18.7.2+, iOS 19–25, iOS 26.0.2+ and current MIE devices are blocked.
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
