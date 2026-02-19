#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATES_DIR="${UPDATES_DIR:-${ROOT_DIR}/dist/updates}"
DOWNLOAD_URL_PREFIX="${DOWNLOAD_URL_PREFIX:-}"
SPARKLE_PRIVATE_KEY="${SPARKLE_PRIVATE_KEY:-}"
ALLOW_UNSIGNED_APPCAST="${ALLOW_UNSIGNED_APPCAST:-0}"

mkdir -p "${UPDATES_DIR}"

GENERATE_APPCAST_BIN="${GENERATE_APPCAST_BIN:-}"
if [[ -z "${GENERATE_APPCAST_BIN}" ]]; then
  GENERATE_APPCAST_BIN="$(find "${ROOT_DIR}/.build" -type f -path "*/Sparkle/bin/generate_appcast" | head -n 1 || true)"
fi

if [[ -z "${GENERATE_APPCAST_BIN}" || ! -x "${GENERATE_APPCAST_BIN}" ]]; then
  echo "Could not find generate_appcast binary. Build once first: scripts/build_app.sh" >&2
  exit 1
fi

ARGS=()
if [[ -n "${DOWNLOAD_URL_PREFIX}" ]]; then
  if [[ "${DOWNLOAD_URL_PREFIX}" != */ ]]; then
    DOWNLOAD_URL_PREFIX="${DOWNLOAD_URL_PREFIX}/"
  fi
  ARGS+=(--download-url-prefix "${DOWNLOAD_URL_PREFIX}")
fi

if [[ -n "${SPARKLE_PRIVATE_KEY}" ]]; then
  if [[ ${#ARGS[@]} -gt 0 ]]; then
    printf '%s' "${SPARKLE_PRIVATE_KEY}" | "${GENERATE_APPCAST_BIN}" --ed-key-file - "${ARGS[@]}" "${UPDATES_DIR}"
  else
    printf '%s' "${SPARKLE_PRIVATE_KEY}" | "${GENERATE_APPCAST_BIN}" --ed-key-file - "${UPDATES_DIR}"
  fi
else
  echo "SPARKLE_PRIVATE_KEY is not set; trying Keychain key lookup..." >&2
  if [[ ${#ARGS[@]} -gt 0 ]]; then
    "${GENERATE_APPCAST_BIN}" "${ARGS[@]}" "${UPDATES_DIR}"
  else
    "${GENERATE_APPCAST_BIN}" "${UPDATES_DIR}"
  fi
fi

if [[ "${ALLOW_UNSIGNED_APPCAST}" != "1" ]] && ! grep -q "sparkle:edSignature" "${UPDATES_DIR}/appcast.xml"; then
  echo "Appcast was generated without sparkle:edSignature. Set SPARKLE_PRIVATE_KEY or configure Keychain signing key." >&2
  exit 1
fi

echo "Generated appcast: ${UPDATES_DIR}/appcast.xml"
