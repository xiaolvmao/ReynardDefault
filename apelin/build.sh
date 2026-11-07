#!/bin/sh
# ReynardDefault on Apelin: builds the SpringBoard tweak and its Settings pane
# with the device toolchain and writes the one package apelin_project_build
# installs. Replaces the repository's Theos makefiles.
set -eu
: "${APELIN_PACKAGE_DIR:?run this through apelin_project_build}"
: "${APELIN_PROJECT_ROOT:?}" "${APELIN_BOOTSTRAP:?}" "${APELIN_ARCHITECTURE:?}"
: "${APELIN_BUILD_ID:?}" "${TMPDIR:?}"
: "${APELIN_PREFIX?}" # set, and empty on roothide
stage="$(mktemp -d "${TMPDIR:?}stage.XXXXXX")"
trap 'rm -rf -- "${stage:?}"' EXIT

cd "${APELIN_PROJECT_ROOT:?}"

TWEAK_NAME="ReynardDefault"

if [ "${APELIN_BOOTSTRAP}" = "roothide" ]; then
	DEFS="-DAPELIN_BOOTSTRAP_ROOTHIDE=1"
	ARCHS="arm64e"
else
	DEFS="-DAPELIN_BOOTSTRAP_ROOTLESS=1"
	ARCHS="arm64 arm64e"
fi
COMMON_CFLAGS="-fobjc-arc -O2 -Wall -Wextra -Wno-unused-parameter \
-Wno-unused-function -fvisibility=hidden -miphoneos-version-min=16.0 ${DEFS}"

mkdir -p "${stage:?}/bin"
tweak_bins=""
for arch in ${ARCHS}; do
	tweak_out="${stage:?}/bin/${TWEAK_NAME}-${arch}.dylib"
	# shellcheck disable=SC2086
	clang -arch "${arch}" ${COMMON_CFLAGS} -dynamiclib \
		-install_name "@loader_path/${TWEAK_NAME}.dylib" \
		-DAPELIN_PACKAGE_ID="\"com.guacforlife.reynarddefault\"" \
		-DAPELIN_BUILD_ID="\"${APELIN_BUILD_ID}\"" \
		Tweak.m -o "${tweak_out}" \
		-framework Foundation
	tweak_bins="${tweak_bins} ${tweak_out}"
done

dylib="${stage:?}/bin/${TWEAK_NAME}.dylib"
# shellcheck disable=SC2086
lipo -create ${tweak_bins} -output "${dylib}"
chmod 0755 "${dylib}"

ldid -S "${dylib}"

pkg="${stage:?}/pkg"
dl="${pkg:?}${APELIN_PREFIX}/Library/MobileSubstrate/DynamicLibraries"
mkdir -p "${dl:?}" "${pkg:?}/DEBIAN"

cp "${dylib}" "${dl:?}/${TWEAK_NAME}.dylib"
cp ReynardDefault.plist "${dl:?}/${TWEAK_NAME}.plist"
chmod 0644 "${dl:?}/${TWEAK_NAME}.plist" "${dl:?}/${TWEAK_NAME}.dylib"

grep -q '^Architecture:' control || { echo "build.sh: control has no Architecture" >&2; exit 1; }
sed "s/^Architecture:.*/Architecture: ${APELIN_ARCHITECTURE}/" control > "${pkg:?}/DEBIAN/control"
chmod 0644 "${pkg:?}/DEBIAN/control"

dpkg-deb -b --root-owner-group "${pkg:?}" "${APELIN_PACKAGE_DIR:?}/"
