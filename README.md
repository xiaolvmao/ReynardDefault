# ReynardDefault

A jailbreak tweak that redirects Safari URL opens to [Reynard](https://github.com/minh-ton/reynard-browser), a Firefox-based browser for iOS.

Any link that would normally open in Safari is intercepted at the SpringBoard level and opened in Reynard instead. There is no switch: it is always on.

## Features

- **Safari redirect** — hooks `FBSystemServiceOpenApplicationRequest` in SpringBoard to swap the bundle identifier

## Requirements

- A jailbroken iOS device — supports **rootless** (Dopamine/Roothide) and **rootful** (unc0ver, palera1n rootful)
- [Reynard](https://github.com/minh-ton/reynard-browser) browser installed

## Building

The source is plain Objective-C (no Logos): `Tweak.m`, built on the device by
`apelin/build.sh` (Apelin workspace project) with the iOS toolchain and
packaged with `dpkg-deb`. It builds `iphoneos-arm64e` for roothide, or
`iphoneos-arm64` for rootless, and writes a single deb.

## Tested Environments

| Device | iOS | Jailbreak | Variant | Status |
|--------|-----|-----------|---------|--------|
| iPhone 14 Pro Max | 16.3.1 | Dopamine (Roothide) | rootless (`iphoneos-arm64`) | Working |
| iPhone 7 | 15.7.7 | Dopamine | rootless (`iphoneos-arm64`) | Working |
| iPhone 7 Plus | 14.8.1 | Taurine 1.1.7-3 | rootful (`iphoneos-arm`) | Working |

Tweak injection via ElleKit (rootless) or substrate (rootful) on arm64 / arm64e.

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.
