#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <path-to-app-or-dmg-or-zip>" >&2
  exit 1
fi

TARGET_PATH="$1"

if [[ ! -e "${TARGET_PATH}" ]]; then
  echo "File not found: ${TARGET_PATH}" >&2
  exit 1
fi

if [[ -n "${APPLE_NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "${TARGET_PATH}" --keychain-profile "${APPLE_NOTARY_PROFILE}" --wait
elif [[ -n "${APPLE_API_KEY_PATH:-}" && -n "${APPLE_API_KEY_ID:-}" && -n "${APPLE_API_ISSUER_ID:-}" ]]; then
  xcrun notarytool submit "${TARGET_PATH}" \
    --key "${APPLE_API_KEY_PATH}" \
    --key-id "${APPLE_API_KEY_ID}" \
    --issuer "${APPLE_API_ISSUER_ID}" \
    --wait
else
  echo "Missing notarization credentials. Set APPLE_NOTARY_PROFILE or (APPLE_API_KEY_PATH, APPLE_API_KEY_ID, APPLE_API_ISSUER_ID)." >&2
  exit 1
fi

if [[ "${TARGET_PATH}" == *.app || "${TARGET_PATH}" == *.dmg ]]; then
  xcrun stapler staple "${TARGET_PATH}"
fi

echo "Notarization complete: ${TARGET_PATH}"
