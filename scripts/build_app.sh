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
APP_ARCHS="${APP_ARCHS:-arm64 x86_64}"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT_DIR}/dist}"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
SPARKLE_FEED_URL="${SPARKLE_FEED_URL:-}"
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"

APP_BUNDLE_PATH="${OUTPUT_DIR}/${APP_NAME}.app"
APP_EXECUTABLE_PATH="${APP_BUNDLE_PATH}/Contents/MacOS/${APP_NAME}"
APP_INFO_PLIST_PATH="${APP_BUNDLE_PATH}/Contents/Info.plist"

is_macho_file() {
  file "$1" | grep -q "Mach-O"
}

merge_macho_file() {
  local first="$1"
  local second="$2"
  local output="$3"
  local first_archs second_archs
  first_archs="$(lipo -archs "$first")"
  second_archs="$(lipo -archs "$second")"

  local -a missing_archs=()
  for arch in $second_archs; do
    if [[ " ${first_archs} " != *" ${arch} "* ]]; then
      missing_archs+=("${arch}")
    fi
  done

  if [[ ${#missing_archs[@]} -eq 0 ]]; then
    return
  fi

  local temp_output="${output}.tmp"
  local -a lipo_inputs=("$first")
  local -a temp_slices=()
  for arch in "${missing_archs[@]}"; do
    local temp_slice="${output}.${arch}.slice.tmp"
    lipo "$second" -extract "$arch" -output "$temp_slice"
    lipo_inputs+=("$temp_slice")
    temp_slices+=("$temp_slice")
  done

  lipo -create "${lipo_inputs[@]}" -output "$temp_output"
  mv -f "$temp_output" "$output"

  for slice in "${temp_slices[@]}"; do
    rm -f "$slice"
  done
}

merge_macho_tree() {
  local base_tree="$1"
  local other_tree="$2"
  while IFS= read -r -d '' base_file; do
    local relative_path="${base_file#${base_tree}/}"
    local other_file="${other_tree}/${relative_path}"
    if [[ ! -f "${other_file}" ]]; then
      continue
    fi
    if is_macho_file "${base_file}" && is_macho_file "${other_file}"; then
      merge_macho_file "${base_file}" "${other_file}" "${base_file}"
    fi
  done < <(find "${base_tree}" -type f -print0)
}

if [[ ! -d "${DEVELOPER_DIR}" ]]; then
  echo "DEVELOPER_DIR does not exist: ${DEVELOPER_DIR}" >&2
  exit 1
fi

read -r -a ARCH_LIST <<< "${APP_ARCHS}"
if [[ ${#ARCH_LIST[@]} -eq 0 ]]; then
  echo "No target architectures provided in APP_ARCHS." >&2
  exit 1
fi

declare -a BUILD_BIN_DIRS=()
declare -a EXECUTABLE_INPUTS=()

for ARCH in "${ARCH_LIST[@]}"; do
  echo "==> Building ${APP_NAME} (${CONFIGURATION}, ${ARCH})"
  DEVELOPER_DIR="${DEVELOPER_DIR}" swift build -c "${CONFIGURATION}" --arch "${ARCH}"
  BUILD_BIN_DIR="$(DEVELOPER_DIR="${DEVELOPER_DIR}" swift build -c "${CONFIGURATION}" --arch "${ARCH}" --show-bin-path)"

  if [[ ! -f "${BUILD_BIN_DIR}/${BUILD_PRODUCT_NAME}" ]]; then
    echo "Could not find built executable for ${ARCH}: ${BUILD_BIN_DIR}/${BUILD_PRODUCT_NAME}" >&2
    exit 1
  fi

  if [[ ! -d "${BUILD_BIN_DIR}/Sparkle.framework" ]]; then
    echo "Could not find Sparkle framework for ${ARCH} at ${BUILD_BIN_DIR}/Sparkle.framework" >&2
    exit 1
  fi

  BUILD_BIN_DIRS+=("${BUILD_BIN_DIR}")
  EXECUTABLE_INPUTS+=("${BUILD_BIN_DIR}/${BUILD_PRODUCT_NAME}")
done
PRIMARY_BIN_DIR="${BUILD_BIN_DIRS[0]}"

echo "==> Creating app bundle at ${APP_BUNDLE_PATH}"
rm -rf "${APP_BUNDLE_PATH}"
mkdir -p "${APP_BUNDLE_PATH}/Contents/MacOS"
mkdir -p "${APP_BUNDLE_PATH}/Contents/Frameworks"
mkdir -p "${APP_BUNDLE_PATH}/Contents/Resources"

if [[ ${#EXECUTABLE_INPUTS[@]} -eq 1 ]]; then
  cp "${EXECUTABLE_INPUTS[0]}" "${APP_EXECUTABLE_PATH}"
else
  lipo -create "${EXECUTABLE_INPUTS[@]}" -output "${APP_EXECUTABLE_PATH}"
fi
chmod +x "${APP_EXECUTABLE_PATH}"
cp -R "${PRIMARY_BIN_DIR}/Sparkle.framework" "${APP_BUNDLE_PATH}/Contents/Frameworks/"

for ((i = 1; i < ${#BUILD_BIN_DIRS[@]}; i++)); do
  merge_macho_tree \
    "${APP_BUNDLE_PATH}/Contents/Frameworks/Sparkle.framework" \
    "${BUILD_BIN_DIRS[i]}/Sparkle.framework"
done

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
