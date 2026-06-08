#!/bin/zsh
set -euo pipefail

APP_NAME="Fresh Start"
OLD_APP_NAMES=("归零" "一键回到初始状态")
BUNDLE_ID="local.reset-mac.manager"
INSTALL_DIR="${1:-$HOME/Applications}"
ROOT_DIR="${0:A:h}"
APP_PATH="$INSTALL_DIR/$APP_NAME.app"
BUILD_DIR="$ROOT_DIR/.build/release"
EXECUTABLE_NAME="ResetMacUI"
ICON_PNG="$ROOT_DIR/assets/AppIcon.png"
ICON_PATH="$ROOT_DIR/assets/AppIcon.icns"
ICONSET_PATH="$ROOT_DIR/assets/AppIcon.iconset"
DONATE_QR_PATH="$ROOT_DIR/assets/DonateQRCode.png"

cd "$ROOT_DIR"
/usr/bin/swift build -c release --product "$EXECUTABLE_NAME"

if [[ ! -f "$ICON_PATH" && -f "$ICON_PNG" ]]; then
  rm -rf "$ICONSET_PATH"
  mkdir -p "$ICONSET_PATH"
  /usr/bin/sips -z 16 16 "$ICON_PNG" --out "$ICONSET_PATH/icon_16x16.png" >/dev/null
  /usr/bin/sips -z 32 32 "$ICON_PNG" --out "$ICONSET_PATH/icon_16x16@2x.png" >/dev/null
  /usr/bin/sips -z 32 32 "$ICON_PNG" --out "$ICONSET_PATH/icon_32x32.png" >/dev/null
  /usr/bin/sips -z 64 64 "$ICON_PNG" --out "$ICONSET_PATH/icon_32x32@2x.png" >/dev/null
  /usr/bin/sips -z 128 128 "$ICON_PNG" --out "$ICONSET_PATH/icon_128x128.png" >/dev/null
  /usr/bin/sips -z 256 256 "$ICON_PNG" --out "$ICONSET_PATH/icon_128x128@2x.png" >/dev/null
  /usr/bin/sips -z 256 256 "$ICON_PNG" --out "$ICONSET_PATH/icon_256x256.png" >/dev/null
  /usr/bin/sips -z 512 512 "$ICON_PNG" --out "$ICONSET_PATH/icon_256x256@2x.png" >/dev/null
  /usr/bin/sips -z 512 512 "$ICON_PNG" --out "$ICONSET_PATH/icon_512x512.png" >/dev/null
  /usr/bin/sips -z 1024 1024 "$ICON_PNG" --out "$ICONSET_PATH/icon_512x512@2x.png" >/dev/null
  /usr/bin/iconutil -c icns "$ICONSET_PATH" -o "$ICON_PATH"
fi

mkdir -p "$INSTALL_DIR"
rm -rf "$APP_PATH"
for old_name in "${OLD_APP_NAMES[@]}"; do
  old_path="$INSTALL_DIR/$old_name.app"
  if [[ "$old_path" != "$APP_PATH" && -d "$old_path" ]]; then
    rm -rf "$old_path"
  fi
done
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"

cp "$BUILD_DIR/$EXECUTABLE_NAME" "$APP_PATH/Contents/MacOS/$EXECUTABLE_NAME"
chmod +x "$APP_PATH/Contents/MacOS/$EXECUTABLE_NAME"

if [[ -f "$ICON_PATH" ]]; then
  cp "$ICON_PATH" "$APP_PATH/Contents/Resources/AppIcon.icns"
fi

if [[ -f "$DONATE_QR_PATH" ]]; then
  cp "$DONATE_QR_PATH" "$APP_PATH/Contents/Resources/DonateQRCode.png"
fi

cat > "$APP_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>zh_CN</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.4.1</string>
  <key>CFBundleVersion</key>
  <string>5</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/plutil -lint "$APP_PATH/Contents/Info.plist" >/dev/null
/usr/bin/codesign --force --deep --sign - "$APP_PATH" >/dev/null 2>&1 || true
/usr/bin/xattr -dr com.apple.quarantine "$APP_PATH" >/dev/null 2>&1 || true

print -r -- "Installed: $APP_PATH"
print -r -- "Tip: drag it to the Dock for one-click access."
