# Eagle 0.3.0 Beta 10

Beta 10 expands Home Screen personalization, adds a clear first-run compatibility briefing and keeps the proven Dock and Dynamic Island engines unchanged.

## What changed

- Expanded **Home Icon Neon** with two styles: diffuse glow and a precise neon outline around visible app icons.
- Added six quick presets, any custom color, three intensity levels and independent page-scoped removal.
- Added **App Name Color** for solid custom Home Screen text colors, with page-owned overlays and independent restore.
- Added temporary one-time **NEW** badges to Aura Studio and App Name Color. Aura Studio's Home card now presents Dynamic Island only; Dock remains available inside the studio.
- Added a one-time welcome screen with the current device assessment, supported ranges, important exclusions, safety guidance and a concise Beta 10 overview.
- Extended Eagle's restrained rainbow identity to loading indicators and the app icon without changing Prepare behavior.
- Added a production safety block for iPhone 16 (`iPhone17,3`) on iOS 18.5 after repeated field restarts.
- Kept the unverified App Library Neon and Battery X experiments out of the release.
- Bumped the app to build `58`.

## Compatibility

- Home Icon Neon and App Name Color are initially allowlisted for iPhone 16 Pro (`iPhone17,1`) on iOS 18.6.2 (`22G100`).
- They are current-page snapshots and can be applied page by page, with up to 24 visible app icons per page.
- Dynamic Island and Dock Aura retain their existing compatibility and safety rules.
- iOS 16.x remains experimental; iOS 17.0–18.7.1 and 26.0–26.0.1 are accepted by the Prepare compatibility policy.
- iOS 18.7.2+, iOS 19–25, iOS 26.0.2+, current MIE devices and iPhone 16 on iOS 18.5 are blocked.
- The IPA is unsigned and must be signed with the user's normal installation method.

## Español

Beta 10 amplía **Neón de iconos** con sombra difuminada y contorno preciso, añade **Color de nombres** para la página de inicio actual y presenta una bienvenida única con compatibilidad, advertencias y novedades. Aura Studio y Color de nombres muestran temporalmente **NUEVO** hasta abrirlos. El iPhone 16 con iOS 18.5 queda bloqueado de forma preventiva después de reportes de reinicios completos. Preparar, Dynamic Island y Dock conservan sus motores existentes. Los experimentos no verificados de Biblioteca de apps y Battery X no forman parte de esta versión.
