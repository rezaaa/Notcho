#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

APP_NAME="${APP_NAME:-Notcho}"
APP_BUNDLE_ID="${APP_BUNDLE_ID:-com.rezamahmoudi.Notcho}"
BUILD_PRODUCT_NAME="${BUILD_PRODUCT_NAME:-NotchTasks}"
APP_VERSION="${APP_VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}"
MIN_SYSTEM_VERSION="${MIN_SYSTEM_VERSION:-13.0}"
CONFIGURATION="${CONFIGURATION:-release}"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT_DIR}/dist}"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
SPARKLE_FEED_URL="${SPARKLE_FEED_URL:-}"
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"

APP_BUNDLE_PATH="${OUTPUT_DIR}/${APP_NAME}.app"
APP_EXECUTABLE_PATH="${APP_BUNDLE_PATH}/Contents/MacOS/${APP_NAME}"
APP_INFO_PLIST_PATH="${APP_BUNDLE_PATH}/Contents/Info.plist"

if [[ ! -d "${DEVELOPER_DIR}" ]]; then
  echo "DEVELOPER_DIR does not exist: ${DEVELOPER_DIR}" >&2
  exit 1
fi

echo "==> Building ${APP_NAME} (${CONFIGURATION})"
DEVELOPER_DIR="${DEVELOPER_DIR}" swift build -c "${CONFIGURATION}"
BUILD_BIN_DIR="$(DEVELOPER_DIR="${DEVELOPER_DIR}" swift build -c "${CONFIGURATION}" --show-bin-path)"

if [[ ! -f "${BUILD_BIN_DIR}/${BUILD_PRODUCT_NAME}" ]]; then
  echo "Could not find built executable: ${BUILD_BIN_DIR}/${BUILD_PRODUCT_NAME}" >&2
  exit 1
fi

if [[ ! -d "${BUILD_BIN_DIR}/Sparkle.framework" ]]; then
  echo "Could not find Sparkle framework at ${BUILD_BIN_DIR}/Sparkle.framework" >&2
  exit 1
fi

echo "==> Creating app bundle at ${APP_BUNDLE_PATH}"
rm -rf "${APP_BUNDLE_PATH}"
mkdir -p "${APP_BUNDLE_PATH}/Contents/MacOS"
mkdir -p "${APP_BUNDLE_PATH}/Contents/Frameworks"
mkdir -p "${APP_BUNDLE_PATH}/Contents/Resources"

cp "${BUILD_BIN_DIR}/${BUILD_PRODUCT_NAME}" "${APP_EXECUTABLE_PATH}"
chmod +x "${APP_EXECUTABLE_PATH}"
cp -R "${BUILD_BIN_DIR}/Sparkle.framework" "${APP_BUNDLE_PATH}/Contents/Frameworks/"

cat > "${APP_INFO_PLIST_PATH}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${APP_BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>LSMinimumSystemVersion</key>
  <string>${MIN_SYSTEM_VERSION}</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>SUAutomaticallyUpdate</key>
  <true/>
  <key>SUEnableAutomaticChecks</key>
  <true/>
</dict>
</plist>
EOF

if [[ -n "${SPARKLE_FEED_URL}" ]]; then
  /usr/libexec/PlistBuddy -c "Add :SUFeedURL string ${SPARKLE_FEED_URL}" "${APP_INFO_PLIST_PATH}"
fi

if [[ -n "${SPARKLE_PUBLIC_ED_KEY}" ]]; then
  /usr/libexec/PlistBuddy -c "Add :SUPublicEDKey string ${SPARKLE_PUBLIC_ED_KEY}" "${APP_INFO_PLIST_PATH}"
fi

if ! otool -l "${APP_EXECUTABLE_PATH}" | grep -q "@executable_path/../Frameworks"; then
  install_name_tool -add_rpath "@executable_path/../Frameworks" "${APP_EXECUTABLE_PATH}"
fi

echo "==> Signing app bundle"
if [[ -n "${SIGNING_IDENTITY}" ]]; then
  codesign --force --deep --options runtime --timestamp --sign "${SIGNING_IDENTITY}" "${APP_BUNDLE_PATH}"
else
  codesign --force --deep --sign - "${APP_BUNDLE_PATH}"
fi

codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE_PATH}"
echo "Built app bundle: ${APP_BUNDLE_PATH}"
