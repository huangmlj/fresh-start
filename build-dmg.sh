#!/bin/zsh
set -euo pipefail

APP_NAME="Fresh Start"
ROOT_DIR="${0:A:h}"
DIST_DIR="$ROOT_DIR/dist"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fresh-start-dmg.XXXXXX")"
APP_BUILD_DIR="$WORK_DIR/app"
DMG_ROOT="$WORK_DIR/dmg-root"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
VOLUME_NAME="$APP_NAME"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$APP_BUILD_DIR" "$DMG_ROOT" "$DIST_DIR"

"$ROOT_DIR/install-app.sh" "$APP_BUILD_DIR" >/dev/null

cp -R "$APP_BUILD_DIR/$APP_NAME.app" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"

cat > "$DMG_ROOT/安装说明.txt" <<TXT
安装方法：

把 Fresh Start.app 拖到 Applications 文件夹即可。
TXT

rm -f "$DMG_PATH"
/usr/bin/hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

/usr/bin/hdiutil verify "$DMG_PATH" >/dev/null

print -r -- "Created: $DMG_PATH"

