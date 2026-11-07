# ReynardDefault — building in Apelin

A jailbreak tweak that redirects Safari's URL opens to Reynard. This folder is
Apelin's `workspace` project for the repository: it has no Theos makefile and
nothing here needs Theos.

## Build

`apelin/build.sh`, declared in `apelin-project.json` as `external.script`, is
the whole build. `apelin_project_build` runs it as mobile in the project root
with the device toolchain first on `PATH`, `SDKROOT` set and
`IPHONEOS_DEPLOYMENT_TARGET=16.0`; it compiles with `clang` and packages with
`dpkg-deb`. It builds `arm64e` for roothide and `arm64` + `arm64e` for
rootless, from `$APELIN_BOOTSTRAP`, and writes one `.deb` into
`$APELIN_PACKAGE_DIR`; `apelin_package_install` then installs it.

Never write the jbroot's real path anywhere: the script uses the `APELIN_*`
variables it is given, and code resolves bootstrap paths at run time.

## What the package installs

- `$APELIN_PREFIX/Library/MobileSubstrate/DynamicLibraries/ReynardDefault.dylib`
  and `ReynardDefault.plist` (filter: `com.apple.springboard` only — the tweak
  is injected into SpringBoard and nowhere else)
- `DEBIAN/control`, taken from `control` with `Architecture` set to
  `$APELIN_ARCHITECTURE`

Package id, name, version and author come from `control`; keep them. There is
no Settings pane and no preference domain: the tweak has no switch.

## Source notes

- `Tweak.m` is the old Logos `Tweak.x` in plain Objective-C:
  `MSHookMessageEx` on `-[FBSystemServiceOpenApplicationRequest
  setBundleIdentifier:]`, whose class is reached with `objc_getClass` (no link
  against FrontBoardServices). `MSHookMessageEx` is looked up with `dlsym` at
  load, not linked: `-undefined dynamic_lookup` would bind the arm64e slice
  without pointer authentication.
- `wrapHTTPURLForReynard` percent-encodes with an RFC 3986 unreserved-only
  static `NSCharacterSet` (`A-Z a-z 0-9 - . _ ~`), so `& = # ; + %` inside the
  original URL survive as part of the `reynard://open?url=` query value.
- `Common/Common.h` keeps the roothide-safe `jbRootPath()` helper
  (`ApelinBootstrapPath`); the tweak itself opens no bootstrap path.

## Check on the device

`apelin_project_build`, then `apelin_package_install`, then
`apelin_package_confirm_loaded` with `respring: true` and target
`SpringBoard`: the dylib logs `ApelinLoaded <build id>` and
`hooked -[FBSystemServiceOpenApplicationRequest setBundleIdentifier:]` from its
constructor, under the log subsystem `com.guacforlife.reynarddefault`.

The redirect itself needs Reynard installed; without it a redirect only fails
to launch, so that behaviour can only be checked on a device with Reynard.
