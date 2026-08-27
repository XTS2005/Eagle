# Eagle Stable Update Notes

Source context for the "Updates" / "Actualizaciones" screen (formerly the beta
welcome). This is copy context only; the visual screen must stay short and must
not mention exploit internals.

## Español — versión corta de usuario (Actualizaciones)

- Prepare ahora valida mejor el dispositivo antes de iniciar.
- Mejor estabilidad al preparar acceso en iOS 17, iOS 18 y builds soportados.
- Mejor manejo de sesiones SpringBoard para evitar estados falsos de "aplicado".
- Dock Aura e Island Aura conservan su motor estable.
- Eagle evita usar datos viejos de otro build después de actualizar iOS.
- Reportes de diagnóstico más útiles cuando algo falla.
- Icon Studio estará disponible próximamente.
- Aura Tint fue retirado temporalmente; Glow, Pulse y Rainbow siguen disponibles.
- Las combinaciones no verificadas se bloquean por seguridad.
- iOS 16 sin combinación verificada queda bloqueado para evitar reinicios.
- iOS 26.6 no se marca compatible porque necesita un motor distinto.

## English — short user-facing version (Updates)

- Prepare now validates the device more carefully before starting.
- Better Prepare stability on iOS 17, iOS 18, and supported builds.
- Better SpringBoard session handling to avoid false "applied" states.
- Dock Aura and Island Aura keep their stable engine.
- Eagle avoids reusing old data after an iOS update.
- Diagnostic reports are clearer when something fails.
- Icon Studio is coming soon.
- Aura Tint was temporarily removed; Glow, Pulse, and Rainbow stay available.
- Unverified combinations are blocked for safety.
- Unverified iOS 16 combinations are blocked to prevent restarts.
- iOS 26.6 is not marked compatible because it needs a different engine.

Honest note / Nota honesta:
If a feature cannot be verified on this device, Eagle should not mark it active.
We validate on real devices first; anything unreliable is temporarily disabled
except Dock Aura and Island Aura.

## Stable wording direction

- Say "Stable update" / "Actualizaciones" instead of "Public Beta".
- Keep the update copy short and user-facing.
- Do not mention exploit internals in the visual screen.
- Keep Dock and Dynamic Island / Aura as required core features on supported
  devices.

## Stability work completed (internal context — not for the visual screen)

- Prepare fails closed on unverified iOS 16.1, 16.1.1, and 16.2 instead of
  starting a risky attempt from a "possible" label.
- iOS 16.7.2 remains available as a tested-limited route.
- iOS 18.7.2 and iOS 26.0.2 or newer remain blocked because the underlying
  kernel issue is fixed there.
- iOS 26.6 is intentionally blocked; it needs a different engine, not a visual
  or offset-only update.
- A16 RemoteCall uses the resolved thread-list offset instead of the old fixed
  iOS 16 value.
- DarkSword retries no longer keep the large search IOSurfaces retained after
  each failed pass, reducing jetsam/restart risk.
- Prepare reports ready only when the kernel primitive has verified proc, task,
  and kernel-base references.
- Offset and kernelcache data are tied to device hardware and system build so
  stale OTA data cannot be reused silently.
- YouTube RemoteCall setup is lazy, so missing YouTube or LiveContainer does not
  create noise before RemoteCall is actually needed.
- RemoteCall sessions are serialized and quarantined after timeout/restart risk.
- Prepare diagnostics include public checkpoint data for crash reports.
- Stable baseline commit context: c26050f (Prepare activation hardening); UI was
  intentionally not edited in that commit, and Dynamic Island and Dock
  render/apply paths were intentionally preserved.
