#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

APP_NAME="${APP_NAME:-Notcho}"
APP_VERSION="${APP_VERSION:-}"
BUILD_NUMBER="${BUILD_NUMBER:-${GITHUB_RUN_NUMBER:-$(date +%Y%m%d%H%M%S)}}"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT_DIR}/dist/releases/${APP_VERSION:-local}}"
NOTARIZE="${NOTARIZE:-0}"
GENERATE_APPCAST="${GENERATE_APPCAST:-1}"

if [[ -z "${APP_VERSION}" ]]; then
  APP_VERSION="$(git -C "${ROOT_DIR}" describe --tags --exact-match 2>/dev/null | sed 's/^v//' || true)"
fi

if [[ -z "${APP_VERSION}" ]]; then
  APP_VERSION="0.1.0-local"
fi

OUTPUT_DIR="${ROOT_DIR}/dist/releases/${APP_VERSION}"
UPDATES_DIR="${OUTPUT_DIR}/updates"

echo "==> Releasing ${APP_NAME} ${APP_VERSION}"
mkdir -p "${OUTPUT_DIR}" "${UPDATES_DIR}"

APP_NAME="${APP_NAME}" \
APP_VERSION="${APP_VERSION}" \
BUILD_NUMBER="${BUILD_NUMBER}" \
OUTPUT_DIR="${OUTPUT_DIR}" \
"${ROOT_DIR}/scripts/build_app.sh"

if [[ "${NOTARIZE}" == "1" ]]; then
  "${ROOT_DIR}/scripts/notarize.sh" "${OUTPUT_DIR}/${APP_NAME}.app"
fi

APP_NAME="${APP_NAME}" APP_VERSION="${APP_VERSION}" OUTPUT_DIR="${OUTPUT_DIR}" \
  "${ROOT_DIR}/scripts/create_zip.sh"

APP_NAME="${APP_NAME}" APP_VERSION="${APP_VERSION}" OUTPUT_DIR="${OUTPUT_DIR}" \
  "${ROOT_DIR}/scripts/create_dmg.sh"

cp -f "${OUTPUT_DIR}/${APP_NAME}-${APP_VERSION}.zip" "${UPDATES_DIR}/"

if [[ "${GENERATE_APPCAST}" == "1" ]]; then
  UPDATES_DIR="${UPDATES_DIR}" "${ROOT_DIR}/scripts/generate_appcast.sh"
  cp -f "${UPDATES_DIR}/appcast.xml" "${OUTPUT_DIR}/appcast.xml"
fi

echo "Release artifacts:"
ls -1 "${OUTPUT_DIR}"
