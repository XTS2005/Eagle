# Eagle 0.3.0 Beta 3

Beta 3 focuses on Aura Studio reliability and clearer device-side diagnostics. Kernel and private SpringBoard behavior remains experimental and device-dependent.

## What changed

- rebuilt Dynamic Island geometry for Standard and Display Zoom layouts;
- made Island neon brighter, thicker and better aligned on iPhone 16 Pro;
- added Glow, Pulse, Rainbow and reversible Tint presentation modes;
- made Tint discover the native adaptive surface and software-black gain-map layers across separate System Aperture scenes;
- made Rainbow attach and verify Island and Dock neon cores before starting motion;
- preserved a visible static aura when iOS rejects a Rainbow animation instead of removing the entire effect;
- restored the Dock bloom and outline while keeping both visual cores independently verified;
- isolated Island and Dock result reporting so one missing host no longer hides the other result;
- added stale RemoteCall detection and one controlled session repair without forcing a respring;
- added the visible `Aura Engine 2026.08.15-r2` identifier so testers can confirm that the newest binary is installed.

## Testing status

- Generic iOS Release build and static analysis pass.
- Primary device target: iPhone 16 Pro, iOS 18.6.2.
- Tint and moving Rainbow still require community testing on a physical device because their private SpringBoard surfaces can differ by device and iOS build.

## Read before installing

- The attached IPA is unsigned.
- Back up important data and test one feature at a time.
- Aura Studio can respring SpringBoard if a private host behaves differently from the tested configuration.
- Confirm that Aura Studio displays `Aura Engine 2026.08.15-r2` before reporting a Beta 3 result.
- Include device model, exact iOS version, selected surfaces and mode, the complete result message, and a screenshot in bug reports.

## Español

Beta 3 mejora profundamente Aura Studio: corrige la búsqueda de Tint, conserva el neón estático si Rainbow no puede mantener su animación, separa los resultados de Island y Dock y repara una sesión remota obsoleta una sola vez sin forzar un respring. Sigue siendo una beta experimental; prueba una función a la vez y confirma que aparezca `Aura Engine 2026.08.15-r2`.
