# Release and Auto-Update Guide

This project now ships with scripts that build a macOS `.app`, package a `.dmg`, and generate a Sparkle `appcast.xml`.

## 1) One-time setup

1. Install full Xcode and make sure commands use it:
   ```bash
   export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
   ```
2. Build once so Sparkle tooling is available in `.build/artifacts`:
   ```bash
   ./scripts/build_app.sh
   ```
3. Generate Sparkle keys (once):
   ```bash
   .build/artifacts/sparkle/Sparkle/bin/generate_keys
   ```
4. Copy the public key into your release env as `SPARKLE_PUBLIC_ED_KEY`.
5. Export and store the private key securely as `SPARKLE_PRIVATE_KEY`:
   ```bash
   .build/artifacts/sparkle/Sparkle/bin/generate_keys -x /tmp/sparkle_private_key.txt
   ```
6. Set a feed URL (example):
   `https://github.com/<owner>/<repo>/releases/latest/download/appcast.xml`

## 2) Local release build

```bash
APP_VERSION=1.0.0 \
BUILD_NUMBER=100 \
SPARKLE_FEED_URL="https://github.com/<owner>/<repo>/releases/latest/download/appcast.xml" \
SPARKLE_PUBLIC_ED_KEY="<public-ed25519-key>" \
SPARKLE_PRIVATE_KEY="<private-ed25519-key>" \
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
DOWNLOAD_URL_PREFIX="https://github.com/<owner>/<repo>/releases/download/v1.0.0" \
./scripts/release.sh
```

Note: `DOWNLOAD_URL_PREFIX` should end with `/`.

Outputs are written to:
`dist/releases/<version>/`

- `<App>-<version>.dmg`
- `<App>-<version>.zip` (used by Sparkle)
- `appcast.xml`

## 3) Notarization (optional but recommended)

Set one of:

- `APPLE_NOTARY_PROFILE` (keychain profile), or
- `APPLE_API_KEY_PATH`, `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID` (App Store Connect API key)

Then run with:

```bash
NOTARIZE=1 ./scripts/release.sh
```

## 4) Automatic releases on Git tags

Workflow file:
`.github/workflows/release.yml`

Trigger:

- Push tag `v*` (example `v1.2.3`), or
- Manual dispatch with `version` input.

Recommended GitHub secrets:

- `APPLE_SIGNING_IDENTITY`
- `APPLE_CERTIFICATE_P12` (base64-encoded `.p12`)
- `APPLE_CERTIFICATE_PASSWORD`
- `APPLE_KEYCHAIN_PASSWORD`
- `APPLE_API_PRIVATE_KEY_P8`
- `APPLE_API_KEY_ID`
- `APPLE_API_ISSUER_ID`
- `SPARKLE_PUBLIC_ED_KEY`
- `SPARKLE_PRIVATE_KEY`
- `SPARKLE_FEED_URL` (optional; workflow has a default)

The workflow creates/updates the release and uploads:

- `.dmg`
- `.zip`
- `appcast.xml`

## 5) App integration details

Sparkle is wired in `Sources/NotchTasks/NotchTasks.swift`.

- Updater starts only when both `SUFeedURL` and `SUPublicEDKey` are present in `Info.plist`.
- A `Check for Updates...` menu item is added to the status bar menu when Sparkle is configured.
