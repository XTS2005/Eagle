# Eagle 0.3.0 Beta 4

Beta 4 ships Aura Engine r7. It focuses on fail-closed Dynamic Island and Dock transactions, independent profiles, faster discovery and diagnostics that distinguish a verified rollback from an unknown SpringBoard state. Kernel and private SpringBoard behavior remains experimental and device-dependent.

## What changed

- separated Island and Dock into independent profiles, including their selected color, mode, preview and applied state;
- enforced one SpringBoard surface per native call so changing the Dock cannot repaint Dynamic Island, or vice versa;
- fixed a physical-device failure where controller discovery exhausted the normal call budget before the Island fallback could attach;
- reserved bounded capacity for Island staging, attachment, read-back, commit and rollback;
- verified the exact Island parent, tag, frame, border and object identity before reporting success;
- made `-12` mean a fully verified rollback and added `-24` for an unknown state that requires closing and reopening Eagle;
- retained the previous verified Island until its replacement is committed, preventing partial or double auras;
- reduced iOS 18 aperture discovery work and skipped Curtain/gain-map restoration when Eagle never applied Tint;
- made the Dock glow and outline commit as an atomic pair with their own critical reserve;
- kept the verified static neon core when SpringBoard rejects Rainbow motion;
- kept Tint behind strict native-host and ownership checks instead of covering music or timer controls with a foreground overlay;
- added a direct bilingual Prepare This iPhone card on the Home screen while preserving the existing preparation controls;
- added the visible `Aura Engine 2026.08.15-r7` and build `7` identifiers for diagnostic reports.

## Testing status

- Generic iOS Debug and Release builds pass with zero build warnings or errors.
- Xcode static analysis passes with no analyzer findings.
- Primary device target: iPhone 16 Pro, iOS 18.6.2.
- Tint, adaptive Island expansion and moving Rainbow still require community testing on physical devices because their private SpringBoard surfaces can differ by device and iOS build.

## Read before installing

- The attached IPA is unsigned.
- Back up important data and test one feature at a time.
- Aura Studio no longer requests an automatic respring, but a private SpringBoard or kernel failure can still respring or reboot the device.
- Test Island and Dock separately. They intentionally keep separate colors and modes.
- Confirm that Aura Studio displays `Aura Engine 2026.08.15-r7` before reporting a Beta 4 result.
- Include device model, exact iOS version, selected surfaces and mode, the complete result message, and a screenshot in bug reports.

## Español

Beta 4 incluye Aura Engine r7. Island y Dock ahora conservan colores y modos independientes, se aplican mediante transacciones separadas y verificadas, y mantienen el efecto anterior cuando un candidato nuevo falla de forma recuperable. También reduce el trabajo de descubrimiento, hace atómico el par luminoso del Dock y distingue entre rollback verificado y estado desconocido. Sigue siendo experimental: prueba una función a la vez y confirma que aparezca `Aura Engine 2026.08.15-r7`.
