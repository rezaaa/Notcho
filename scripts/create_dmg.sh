#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${APP_NAME:-Notcho}"
APP_VERSION="${APP_VERSION:-0.1.0}"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT_DIR}/dist}"
APP_ICON_NAME="${APP_ICON_NAME:-AppIcon}"

APP_BUNDLE_PATH="${OUTPUT_DIR}/${APP_NAME}.app"
STAGING_DIR="${OUTPUT_DIR}/.dmg-staging"
DMG_PATH="${OUTPUT_DIR}/${APP_NAME}-${APP_VERSION}.dmg"
VOLUME_ICON_PATH="${STAGING_DIR}/.VolumeIcon.icns"

if [[ ! -d "${APP_BUNDLE_PATH}" ]]; then
  echo "App bundle not found at ${APP_BUNDLE_PATH}" >&2
  echo "Run scripts/build_app.sh first." >&2
  exit 1
fi

rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"
cp -R "${APP_BUNDLE_PATH}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

if [[ -f "${APP_BUNDLE_PATH}/Contents/Resources/${APP_ICON_NAME}.icns" ]]; then
  cp "${APP_BUNDLE_PATH}/Contents/Resources/${APP_ICON_NAME}.icns" "${VOLUME_ICON_PATH}"
  if command -v SetFile >/dev/null 2>&1; then
    SetFile -a C "${STAGING_DIR}" || true
    SetFile -a V "${VOLUME_ICON_PATH}" || true
  elif xcrun -find SetFile >/dev/null 2>&1; then
    "$(xcrun -find SetFile)" -a C "${STAGING_DIR}" || true
    "$(xcrun -find SetFile)" -a V "${VOLUME_ICON_PATH}" || true
  else
    echo "Warning: SetFile not available; skipping DMG volume custom icon flag."
  fi
fi

rm -f "${DMG_PATH}"
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

rm -rf "${STAGING_DIR}"
echo "Created dmg: ${DMG_PATH}"
