# Lara Custom

This is an independent working copy of Lara. The upstream source project is not
modified, and pushes to the `upstream` remote are disabled intentionally.

## App identity

- Display name: `Lara Custom`
- Bundle identifier: `com.leonardobaptiste.laracustom`
- Xcode scheme: `lara`

## Current experience

The original tab interface is no longer mounted. `LaraHomeView` is the only
root experience and intentionally exposes three destinations:

- **Wallpapers** — browses the official Nugget Wallpapers community and Apple
  catalogs, imports compatible `.tendies` descriptors, or converts a video of
  up to 12 seconds into a Pocket Poster-compatible descriptor.
- **Cards** — keeps Lara's existing Wallet card discovery, backup, overwrite,
  restore, and card-number-suffix engine behind a simpler interface.
- **Passcode style** — browses the official community passcode catalog, imports
  `.passthm` files, previews each key, applies individual replacements, and
  preserves Lara's original restore engine.

Legacy feature views remain in the source tree as dormant implementation
references, but they are not reachable from the app. This keeps upstream code
available as an engine for future features without exposing unused options to
the user.

## Adding a tweak

1. Identify the minimum capability it needs: `exploit`, `vfs`, `sandbox`, or
   `remoteCall`.
2. Implement the operation in its own focused view or service. Reuse `laramgr`
   for exploit and filesystem primitives.
3. Add one intentional feature card to `LaraHomeView`; do not restore the old
   toolbox-style navigation.
4. Use `LaraAccessView` before any operation that needs sandbox access.
5. Test failure, cancellation, retry, and unsupported-device paths in addition
   to the successful path.

Do not present a tweak as available when its required capability has not been
initialized. Avoid making kernel or filesystem operations automatically on app
launch; keep them behind an explicit user action and report the result in the
existing logger.
