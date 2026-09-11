#!/bin/bash
set -e

cd "$(dirname "$0")/.."

# Отмонтировать любые старые тома Movia, чтобы не было дублей /Volumes/Movia 1
for m in $(hdiutil info | grep '/Volumes/Movia' | awk '{print $1}'); do
    hdiutil detach "$m" -force 2>/dev/null || true
done

echo "Шаг 1: Сборка актуального бандла Movia.app с моделями..."
./Scripts/build_app.sh

echo "Шаг 2: Подготовка содержимого для DMG..."
DMG_STAGING="./build/dmg_staging"
FINAL_DMG="./build/Movia.dmg"
TMP_DMG="./build/tmp_rw.dmg"

rm -rf "$DMG_STAGING" "$TMP_DMG" "$FINAL_DMG"
mkdir -p "$DMG_STAGING/.background"

# 1. Копирование Movia.app
cp -R "./build/Movia.app" "$DMG_STAGING/"

# 2. Ссылка на Applications
ln -s /Applications "$DMG_STAGING/Applications"

# 3. Фон окна DMG
if [ -f "Resources/dmg_background.png" ]; then
    cp "Resources/dmg_background.png" "$DMG_STAGING/.background/dmg_background.png"
fi

# Примечание: иконку тома .VolumeIcon.icns намеренно НЕ устанавливаем, 
# чтобы на рабочем столе отображалась стандартная дефолтная иконка диска macOS.

echo "Шаг 3: Создание временного DMG для настройки Finder..."
hdiutil create -ov -srcfolder "$DMG_STAGING" -volname "Movia" -format UDRW "$TMP_DMG"

MOUNT_INFO=$(hdiutil attach -readwrite -noverify -noautoopen "$TMP_DMG")
DEV_NAME=$(echo "$MOUNT_INFO" | egrep '^/dev/' | head -n 1 | awk '{print $1}')
VOLUME_PATH=$(echo "$MOUNT_INFO" | grep '/Volumes/' | awk -F '/Volumes/' '{print "/Volumes/" $2}')

echo "Примонтирован том $VOLUME_PATH на $DEV_NAME"

echo "Шаг 4: Оформление окна установщика..."
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "Movia"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {250, 150, 910, 590}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 140
        set text size of viewOptions to 13
        set background color of viewOptions to {0, 0, 0}
        try
            set background picture of viewOptions to (POSIX file "$VOLUME_PATH/.background/dmg_background.png" as alias)
        end try
        set position of item "Movia.app" of container window to {165, 215}
        set position of item "Applications" of container window to {495, 215}
        try
            set extension hidden of item "Movia.app" of container window to true
        end try
        close
        open
        update without registering applications
        delay 1
    end tell
end tell
APPLESCRIPT

# Проверяем и гарантируем нулевые RGB-значения фона в .DS_Store
python3 -c "
import os, plistlib
ds_path = '$VOLUME_PATH/.DS_Store'
if os.path.exists(ds_path):
    with open(ds_path, 'rb') as f:
        data = f.read()
    idx = data.find(b'bplist00')
    while idx != -1:
        for end in range(idx + 16, len(data)):
            try:
                pl = plistlib.loads(data[idx:end])
                if 'backgroundColorRed' in pl:
                    print('Проверка .DS_Store: backgroundColor = (' + str(pl.get('backgroundColorRed')) + ', ' + str(pl.get('backgroundColorGreen')) + ', ' + str(pl.get('backgroundColorBlue')) + ')')
                break
            except Exception:
                continue
        idx = data.find(b'bplist00', idx + 1)
" || true

sync
sleep 1

echo "Шаг 5: Отмонтирование и упаковка в финальный DMG (UDRO)..."
hdiutil detach "$DEV_NAME" -force || true

hdiutil convert "$TMP_DMG" -format UDRO -o "$FINAL_DMG"

rm -rf "$TMP_DMG" "$DMG_STAGING"

echo "Готово! Финальный DMG собран:"
ls -lh "$FINAL_DMG"
