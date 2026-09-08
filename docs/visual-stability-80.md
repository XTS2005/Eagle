# Eagle 1.0.3 (80) — visual pass and release status

The home Customize screen now removes the New badge from Aura Studio. Island Gallery, Dock Gallery, Hide Dock + Island, and App Name Color use a shared monochrome New badge: white with black text in dark mode and black with white text in light mode. The same badge is used by the remaining visual entry that announces a new feature, so the accent gradient no longer changes its meaning.

The Updates screen now includes the implemented gallery controls, Save/Static/Live presentation, adjustable Island shadow, Dock glow, separated Hide Dock + Island controls, visible Apply/Prepare actions, alignment and Glow/Pulse fixes, safer theme-session handling, Hide Dock recovery checks, invalid preference guards, Passcode/Collections recovery work, and Prepare cleanup. It also states that Hide Dock requires respring and must be reapplied after a full restart.

The Updates screen was previewed in Spanish and English, dark and light appearance, and large text. The support badge uses `ViewThatFits` so it moves below the device title instead of colliding at large accessibility sizes. Home cards were previewed in both appearances; Aura Studio has no New badge and the other current entries show the monochrome badge.

Build 1.0.4 (80) compiles successfully with no build errors. The simulator-only visual preview compiles and launches. IPA: `build/Eagle-1.0.4-80.ipa`; the final release hash is recorded in the GitHub release. ZIP integrity is verified and the unsigned package contains no embedded provisioning profile or `_CodeSignature`.

Before calling this a stable public release, one physical pass remains: install on the reference iPhone, open the updated screens, apply Island and Dock themes repeatedly, test Hide Dock and Restore with respring, and confirm the expected loss of the Dock material change after a full reboot. GitHub publication metadata and the public release upload are also still pending.
