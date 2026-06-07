#!/bin/sh
set -eu

APP_NAME="Masklet"
DISPLAY_NAME="Masklet"
VERSION="${VERSION:-0.1.0}"
ARCH="${ARCH:-native}"

case "${ARCH}" in
  native)
    BUILD_ARCH_DIR="native"
    DMG_ARCH_SUFFIX=""
    ;;
  arm64)
    BUILD_ARCH_DIR="arm64"
    DMG_ARCH_SUFFIX="-apple-silicon"
    ;;
  x86_64)
    BUILD_ARCH_DIR="x86_64"
    DMG_ARCH_SUFFIX="-intel"
    ;;
  *)
    echo "Unsupported ARCH: ${ARCH}. Use native, arm64, or x86_64." >&2
    exit 1
    ;;
esac

APP_BUNDLE=".build/app/${BUILD_ARCH_DIR}/${APP_NAME}.app"
DIST_DIR="dist"
DMG_NAME="${APP_NAME}-${VERSION}${DMG_ARCH_SUFFIX}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"
STAGING_DIR=".build/dmg/${BUILD_ARCH_DIR}/${DISPLAY_NAME}"

ARCH="${ARCH}" ./scripts/build_app.sh

rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}" "${DIST_DIR}"
cp -R "${APP_BUNDLE}" "${STAGING_DIR}/${DISPLAY_NAME}.app"
ln -s /Applications "${STAGING_DIR}/Applications"

rm -f "${DMG_PATH}"
hdiutil create \
  -volname "${DISPLAY_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

echo "${DMG_PATH}"
