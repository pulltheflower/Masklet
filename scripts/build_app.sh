#!/bin/sh
set -eu

APP_NAME="Masklet"
EXECUTABLE_NAME="SensitivePasteGuard"
VERSION="${VERSION:-0.1.0}"
BUNDLE_VERSION="${BUNDLE_VERSION:-1}"
ARCH="${ARCH:-native}"

case "${ARCH}" in
  native)
    TRIPLE=""
    BUILD_ARCH_DIR="native"
    ;;
  arm64)
    TRIPLE="arm64-apple-macosx14.0"
    BUILD_ARCH_DIR="arm64"
    ;;
  x86_64)
    TRIPLE="x86_64-apple-macosx14.0"
    BUILD_ARCH_DIR="x86_64"
    ;;
  *)
    echo "Unsupported ARCH: ${ARCH}. Use native, arm64, or x86_64." >&2
    exit 1
    ;;
esac

BUNDLE_DIR=".build/app/${BUILD_ARCH_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

if [ -n "${TRIPLE}" ]; then
  env CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/masklet-clang-cache}" SWIFTPM_CACHE_PATH="${SWIFTPM_CACHE_PATH:-/private/tmp/masklet-swiftpm-cache}" swift build -c release -Xswiftc -target -Xswiftc "${TRIPLE}"
  BIN_DIR="$(env CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/masklet-clang-cache}" SWIFTPM_CACHE_PATH="${SWIFTPM_CACHE_PATH:-/private/tmp/masklet-swiftpm-cache}" swift build -c release -Xswiftc -target -Xswiftc "${TRIPLE}" --show-bin-path)"
else
  env CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/masklet-clang-cache}" SWIFTPM_CACHE_PATH="${SWIFTPM_CACHE_PATH:-/private/tmp/masklet-swiftpm-cache}" swift build -c release
  BIN_DIR=".build/release"
fi
if [ -z "${PYTHON_BIN:-}" ]; then
  BUNDLED_PYTHON="/Users/zzh/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
  if [ -x "${BUNDLED_PYTHON}" ]; then
    PYTHON_BIN="${BUNDLED_PYTHON}"
  else
    PYTHON_BIN="python3"
  fi
fi
"${PYTHON_BIN}" scripts/build_icns.py >/dev/null

rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"
cp "${BIN_DIR}/${EXECUTABLE_NAME}" "${MACOS_DIR}/${APP_NAME}"
cp "Resources/Icons/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
cp "Resources/Icons/MenuBarIcon.png" "${RESOURCES_DIR}/MenuBarIcon.png"

cat > "${CONTENTS_DIR}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>Masklet</string>
  <key>CFBundleIdentifier</key>
  <string>local.masklet.app</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Masklet</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUNDLE_VERSION}</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Local prototype</string>
</dict>
</plist>
PLIST

echo "${BUNDLE_DIR}"
