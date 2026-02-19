#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${APP_NAME:-Notcho}"
APP_VERSION="${APP_VERSION:-0.1.0}"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT_DIR}/dist}"

APP_BUNDLE_PATH="${OUTPUT_DIR}/${APP_NAME}.app"
STAGING_DIR="${OUTPUT_DIR}/.dmg-staging"
DMG_PATH="${OUTPUT_DIR}/${APP_NAME}-${APP_VERSION}.dmg"

if [[ ! -d "${APP_BUNDLE_PATH}" ]]; then
  echo "App bundle not found at ${APP_BUNDLE_PATH}" >&2
  echo "Run scripts/build_app.sh first." >&2
  exit 1
fi

rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"
cp -R "${APP_BUNDLE_PATH}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

rm -f "${DMG_PATH}"
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

rm -rf "${STAGING_DIR}"
echo "Created dmg: ${DMG_PATH}"
