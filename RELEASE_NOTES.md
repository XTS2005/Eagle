# Eagle 0.3.0 Beta 6

Beta 6 restores the Dock Aura renderer from the last device-proven build and hardens its discovery path after Beta 5 reports showed the protected remote channel failing before any Dock view was drawn. It remains experimental and requires physical-device testing.

## What changed

- restored the proven Dock outline and diffuse behind-icon glow geometry;
- kept Display Zoom-aware scaling while restoring the original z-order, clipping and mask behavior;
- replaced the Dock candidate's NSInvocation-based retain with a direct remote retain to reduce SpringBoard transport failures;
- added per-selector discovery breadcrumbs so a future failure identifies the exact Dock step;
- preserved independent Island/Dock colors and one-surface-per-call behavior;
- retained the fail-closed rule: a failed Rainbow animation cannot remove a verified static Glow;
- bumped the visible Aura Engine to `2026.08.16-r10-dock-proven` and app build to `13`.

## Testing status

- Generic iOS Debug and Release builds pass.
- Xcode static analysis passes.
- The Dock must still be tested on a physical iPhone; no simulator can validate private SpringBoard behavior.
- Primary development target: iPhone 16 Pro, iOS 18.6.2.

## Read before installing

- The IPA is unsigned.
- Test Dock Glow first, then Rainbow separately.
- If Dock fails, share the diagnostic report before repeating the operation.
- This is still a beta and can remain device- or iOS-version-dependent.

## Español

Beta 6 restaura el renderer del Dock que sí había funcionado en el dispositivo y reduce el fallo del canal remoto antes de dibujar la luz. También conserva Display Zoom, colores independientes y el brillo estático aunque Rainbow no pueda iniciar. Sigue siendo experimental: prueba primero Glow, comparte el diagnóstico si falla y no lo trates como una versión estable.

# Eagle 0.3.0 Beta 5

Beta 5 ships Aura Engine r8 and a rebuilt Prepare pipeline. It addresses repeated Prepare crashes on A17/iOS 17 devices, replaces unbounded exploit retries with a fail-closed transaction, adds durable shareable diagnostics, and removes the recursive Dock lookup that trapped Beta 4 on a live SpringBoard host. Kernel and private SpringBoard behavior remains experimental and device-dependent.

## What changed

- made every Prepare button share one guarded transaction, blocking duplicate native attempts and stale callbacks;
- added a persistent Prepare journal and a bilingual **Share Crash Report** recovery card after an interrupted attempt;
- bounded non-A18 and A18 acquisition loops, physical read retries, corruption retries and total acquisition time;
- stopped before kernel walking unless the primitive, sockets, pointers, retention writes and read-back are verified;
- fixed the A18 Pro CPU-family classification and added dynamic tracking/cleanup for the A18 IOSurface spray;
- tied saved offsets to the exact device, iOS build, CPU family and schema, and made **Clear offsets** remove the actual saved offset keys;
- applied the compatibility matrix: iOS 16.x experimental; 16.7.2 limited testing; iOS 17.0–18.7.1 supported; iOS 18.7.2+, 19–25 and 26.0.2+ blocked; iOS 26.0–26.0.1 supported on eligible hardware;
- added a fail-closed Dynamic Island hardware matrix beginning with iPhone 14 Pro/Pro Max; models without Island keep Dock available;
- rebuilt Dock Aura around a retained, dock-sized host and direct retained child snapshots instead of recursive `viewWithTag:` calls;
- made Dock glow and outline a pointer-verified atomic pair with rollback; Rainbow starts only after both static cores commit;
- retained independent Island and Dock colors, modes and applied states, one surface per native call;
- added the visible `Aura Engine 2026.08.15-r8` and app build `10` identifiers.

## Testing status

- Generic iOS Debug and Release builds pass with zero build warnings or errors.
- Xcode static analysis passes with no analyzer findings.
- Primary development target: iPhone 16 Pro, iOS 18.6.2.
- The new A17/iOS 17 Prepare path, rebuilt Dock transaction, Tint, adaptive Island expansion and moving Rainbow still require community testing on physical devices.
- Simulator compilation can verify UI/model classification only; the kernel and private SpringBoard paths cannot be validated there.

## Read before installing

- The attached IPA is unsigned.
- Back up important data and test one feature at a time.
- Aura Studio no longer requests an automatic respring, but a private SpringBoard or kernel failure can still respring or reboot the device.
- Prepare once. If the device restarts or Eagle reports an interrupted attempt, reopen Eagle and share its generated report instead of repeatedly pressing Prepare.
- Test Island and Dock separately. They intentionally keep separate colors and modes.
- Aura Studio live changes remain limited to verified iOS 17/18 SpringBoard routes even where Prepare supports another iOS release.
- Confirm that Aura Studio displays `Aura Engine 2026.08.15-r8` and that the app build is `10` before reporting a Beta 5 result.
- Include device model, exact iOS version, selected surface and mode, the complete result message, diagnostic report and screenshot in bug reports.

## Español

Beta 5 incluye Aura Engine r8 y reconstruye el flujo Prepare. Los intentos kernel ahora tienen límites, validación antes de continuar, limpieza segura y un reporte compartible si Eagle o el iPhone se interrumpen. Dock Aura deja de recorrer recursivamente la jerarquía que provocaba el trap de Beta 4 y confirma su brillo y contorno como un solo par atómico. Sigue siendo experimental: prepara una sola vez, prueba Island y Dock por separado y comparte el diagnóstico si algo falla.
