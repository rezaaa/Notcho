#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${APP_NAME:-NotchTasks}"
APP_VERSION="${APP_VERSION:-0.1.0}"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT_DIR}/dist}"

APP_BUNDLE_PATH="${OUTPUT_DIR}/${APP_NAME}.app"
ZIP_PATH="${OUTPUT_DIR}/${APP_NAME}-${APP_VERSION}.zip"

if [[ ! -d "${APP_BUNDLE_PATH}" ]]; then
  echo "App bundle not found at ${APP_BUNDLE_PATH}" >&2
  echo "Run scripts/build_app.sh first." >&2
  exit 1
fi

rm -f "${ZIP_PATH}"
ditto -c -k --sequesterRsrc --keepParent "${APP_BUNDLE_PATH}" "${ZIP_PATH}"
echo "Created zip: ${ZIP_PATH}"
