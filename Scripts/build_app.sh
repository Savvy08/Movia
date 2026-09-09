#!/bin/bash
set -e

echo "🔨 Компиляция Movia для Apple Silicon (Release arm64)..."
cd "$(dirname "$0")/.."

swift build -c release --arch arm64

APP_NAME="Movia"
APP_DIR="./build/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Создание бандла $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Скопировать бинарник
cp .build/arm64-apple-macosx/release/$APP_NAME "$MACOS_DIR/$APP_NAME"

# Скопировать Info.plist
cp Info.plist "$CONTENTS_DIR/Info.plist"

# Скопировать иконку
if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
fi

# Подписать бандл ad-hoc
echo "🔏 Подпись приложения..."
codesign --force --deep --sign - "$APP_DIR"

echo "✅ Приложение $APP_NAME.app успешно собрано в: $APP_DIR"
