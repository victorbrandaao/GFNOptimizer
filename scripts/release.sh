#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: scripts/release.sh <version>"
  echo "Exemplo: scripts/release.sh 1.3.2"
  exit 1
fi

VERSION="$1"
APP_NAME="CloudBoost"
BUNDLE_ID="com.gfnbooster.app"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/.release"
APP_DIR="$WORK_DIR/${APP_NAME}.app"
DMG_PATH="$ROOT_DIR/${APP_NAME}_v${VERSION}.dmg"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

echo "[1/6] Limpando artefatos temporarios"
rm -rf "$WORK_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

echo "[2/6] Build release com SwiftPM"
swift build -c release --package-path "$ROOT_DIR"

BIN_PATH="$ROOT_DIR/.build/release/$APP_NAME"
if [[ ! -f "$BIN_PATH" ]]; then
  echo "Erro: binario nao encontrado em $BIN_PATH"
  exit 1
fi

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

if [[ -f "$ROOT_DIR/AppIcon.icns" ]]; then
  cp "$ROOT_DIR/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

echo "[3/6] Gerando Info.plist da release"
cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${VERSION}</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>CFBundleIconFile</key>
  <string>AppIcon.icns</string>
</dict>
</plist>
EOF

echo "[4/6] Assinando bundle"
codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_DIR"

echo "[5/6] Validando assinatura"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "[6/6] Gerando DMG"
STAGE_DIR="$WORK_DIR/dmg"
mkdir -p "$STAGE_DIR"
cp -R "$APP_DIR" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"
rm -f "$DMG_PATH"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE_DIR" -ov -format UDZO "$DMG_PATH" >/dev/null

echo
echo "Release pronta: $DMG_PATH"
echo "Bundle gerado em: $APP_DIR"
echo "Dica: para assinatura Developer ID, rode com SIGN_IDENTITY='Developer ID Application: Seu Nome (TEAMID)'"