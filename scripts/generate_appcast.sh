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
  # Normalize secrets copied from UI/CLI (strip quotes and whitespace/newlines).
  SPARKLE_PRIVATE_KEY="${SPARKLE_PRIVATE_KEY%\"}"
  SPARKLE_PRIVATE_KEY="${SPARKLE_PRIVATE_KEY#\"}"
  SPARKLE_PRIVATE_KEY="$(printf '%s' "${SPARKLE_PRIVATE_KEY}" | tr -d '[:space:]')"

  if [[ ! "${SPARKLE_PRIVATE_KEY}" =~ ^[A-Za-z0-9+/=]+$ ]]; then
    echo "SPARKLE_PRIVATE_KEY is not valid base64. Re-export with generate_keys -x and update the GitHub secret." >&2
    exit 1
  fi

  if ! (printf '%s' "${SPARKLE_PRIVATE_KEY}" | base64 --decode >/dev/null 2>&1 || printf '%s' "${SPARKLE_PRIVATE_KEY}" | base64 -D >/dev/null 2>&1); then
    echo "SPARKLE_PRIVATE_KEY cannot be base64-decoded. Use the exact output of generate_keys -x (single line)." >&2
    exit 1
  fi

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
