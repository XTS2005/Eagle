# Eagle architecture notes

Eagle is an independent AGPL-3.0 modification of Lara. The `upstream` remote is
kept read-only so Eagle changes cannot accidentally be pushed to Lara.

## App identity

- Display name and product: `Eagle`
- Bundle identifier: `com.leonardobaptiste.laracustom`
- Xcode project and scheme: `lara.xcodeproj` / `lara`
- Primary navigation: `LaraHomeView`
- Interface languages: English and Spanish through `LaraL10n`

Internal Lara-prefixed Swift symbols and the `lara.log` filename remain where a
rename would add risk without changing the user experience. New user-facing
copy should say Eagle.

## Public beta features

- Complete Styles and Eagle Match
- Animated and community wallpapers
- Wallet card artwork
- Passcode themes
- Icon Studio (beta)
- Six-app Dock experiments
- Island Aura (experimental native route plus compact fallback)
- Eagle System: Guardian, Scenes and safe sharing

## Adding a feature

1. Start with a repeated user need, not a private API name.
2. Identify the minimum capability: exploit, VFS, sandbox escape or RemoteCall.
3. Keep every mutation behind an explicit user action.
4. Use `LaraAccessView` for prerequisites and fail before changing anything
   when the required capability is unavailable.
5. Verify the result before reporting success and provide a reversible restore
   path whenever the underlying operation permits it.
6. Add English and Spanish text together.
7. Test cancellation, retry, debugger attachment and unsupported-device paths.
8. Document experimental behavior in the README and bug-report template.

Do not automatically run kernel or filesystem mutations at launch. Never report
a private SpringBoard change as applied solely because its write call returned.
