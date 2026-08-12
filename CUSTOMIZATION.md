# Lara Custom

This is an independent working copy of Lara. The upstream source project is not
modified, and pushes to the `upstream` remote are disabled intentionally.

## App identity

- Display name: `Lara Custom`
- Bundle identifier: `com.leonardobaptiste.laracustom`
- Xcode scheme: `lara`

## Removing options

Visible features are controlled from
`lara/config/LaraCustomProfile.swift`. Add a `LaraFeature` case to
`disabledFeatures` to hide it. Keeping the feature's implementation in the tree
makes upstream merges easier and lets the option be restored later.

The permanently disabled `DarkBoard` row was removed from the custom menu
because it did not expose a working action.

## Adding a tweak

1. Identify the minimum capability it needs: `exploit`, `vfs`, `sandbox`, or
   `remoteCall`.
2. Add a case to `LaraFeature` and declare its `supportedCapabilityPaths`.
3. Implement the operation in its own view or service. Reuse `laramgr` for
   exploit and filesystem primitives.
4. Add the navigation row to `TweaksView` and preserve Lara's existing readiness
   checks before enabling it.
5. Test failure, cancellation, retry, and unsupported-device paths in addition
   to the successful path.

Do not present a tweak as available when its required capability has not been
initialized. Avoid making kernel or filesystem operations automatically on app
launch; keep them behind an explicit user action and report the result in the
existing logger.
