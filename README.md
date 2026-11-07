# ReynardDefault

A jailbreak tweak that redirects Safari URL opens to [Reynard](https://github.com/minh-ton/reynard-browser), a Firefox-based browser for iOS.

Any link that would normally open in Safari is intercepted at the SpringBoard level and opened in Reynard instead. There is no switch: it is always on.

> **This is a modified version of [guacforlife/ReynardDefault](https://github.com/guacforlife/ReynardDefault).**
> The original tweak is by [guacforlife](https://github.com/guacforlife); this copy is
> maintained by [xiaolvmao](https://github.com/xiaolvmao) and differs as described in
> [What changed in 1.5.0](#what-changed-in-150) below. It is not affiliated with or
> endorsed by the original author. Licensed under the GPL-3.0, like the original.

## Features

- **Safari redirect** — hooks `FBSystemServiceOpenApplicationRequest` in SpringBoard to swap the bundle identifier

## What changed in 1.5.0

### Fixed

- **URL encoding of `reynard://open?url=`** — the query value was encoded with
  `URLQueryAllowedCharacterSet`, which leaves `& = # ; + %` as they are, so the
  first of them ended the query and left Reynard with a truncated URL. It now
  uses a static, `dispatch_once`-initialised character set holding only the
  RFC 3986 unreserved characters (`A-Z a-z 0-9 - . _ ~`).

### Changed

- **No Logos, no Theos.** `Tweak.x` is now `Tweak.m`: the same hook on
  `-[FBSystemServiceOpenApplicationRequest setBundleIdentifier:]`, installed with
  `MSHookMessageEx` (resolved with `dlsym` at load). The class is still looked up
  at runtime with `objc_getClass`, so nothing links the private
  FrontBoardServices. The browser whitelist and the SpringBoard-only filter are
  unchanged.
- **Built on the device.** `apelin/build.sh` compiles the tweak with clang and
  packages it with `dpkg-deb`: `iphoneos-arm64e` for roothide, `iphoneos-arm64`
  for rootless, one deb each.

### Removed

- **Control Centre toggle** — `ReynardDefaultCC/` and the `com.opa334.ccsupport`
  dependency are gone.
- **Settings pane** — `ReynardDefaultPrefs` (the PreferenceLoader bundle and its
  `enabled` switch) is gone, along with the `preferenceloader` dependency. The
  tweak no longer reads a preference: whitelisted browser opens are always
  redirected.

Package identity is unchanged: `com.guacforlife.reynarddefault`, version 1.5.0,
maintained by guacforlife, GPL-3.0.

## Requirements

- A jailbroken iOS device — supports **rootless** (Dopamine/Roothide) and **rootful** (unc0ver, palera1n rootful)
- [Reynard](https://github.com/minh-ton/reynard-browser) browser installed

## Building

The source is plain Objective-C (no Logos): `Tweak.m`, built by `apelin/build.sh`
with the iOS toolchain (`clang`) and packaged with `dpkg-deb`. Nothing here needs
Theos.

The script is declared in `apelin-project.json` and is run by Apelin's build,
which hands it the target: `APELIN_BOOTSTRAP` (`roothide` or `rootless`),
`APELIN_ARCHITECTURE`, and the folder to write the deb into.

## Tested Environments

| Device | iOS | Jailbreak | Variant | Status |
|--------|-----|-----------|---------|--------|
| iPhone 14 Pro Max | 16.3.1 | Dopamine (Roothide) | rootless (`iphoneos-arm64`) | Working |
| iPhone 7 | 15.7.7 | Dopamine | rootless (`iphoneos-arm64`) | Working |
| iPhone 7 Plus | 14.8.1 | Taurine 1.1.7-3 | rootful (`iphoneos-arm`) | Working |

Tweak injection via ElleKit (rootless) or substrate (rootful) on arm64 / arm64e.

On iOS 17.0 / roothide the 1.5.0 package builds, installs, and its dylib loads
into SpringBoard with the hook installed. The redirect itself was not tested
there: it needs Reynard installed.

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.
