#!/bin/bash
set -e

echo "=== Budowanie aplikacji Tidy dla macOS ==="

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# 1. Generowanie ikon, jeśli brak
if [ ! -f "Tidy/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" ]; then
    echo ">> Generowanie ikon aplikacji..."
    swift generate_user_icons.swift
fi

# 2. Generowanie projektu Xcode
echo ">> Konfiguracja projektu Tidy.xcodeproj..."
python3 generate_xcodeproj.py

# 3. Kompilacja i budowanie wersji Release
echo ">> Kompilacja projektu Tidy (Release)..."
xcodebuild -project Tidy.xcodeproj \
           -scheme Tidy \
           -configuration Release \
           -derivedDataPath .build/xcode \
           build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO

APP_PATH=".build/xcode/Build/Products/Release/Tidy.app"

if [ -d "$APP_PATH" ]; then
    mkdir -p dist
    rm -rf dist/Tidy.app
    cp -R "$APP_PATH" dist/Tidy.app
    if [ -f "Tidy/Resources/AppIconLight.png" ]; then
        cp Tidy/Resources/AppIconLight.png dist/Tidy.app/Contents/Resources/
    fi
    if [ -f "Tidy/Resources/AppIconDark.png" ]; then
        cp Tidy/Resources/AppIconDark.png dist/Tidy.app/Contents/Resources/
    fi
    echo ""
    echo "=========================================================="
    echo " SUKCES: Aplikacja została zbudowana pomyślnie!"
    echo " Ścieżka: $PROJECT_DIR/dist/Tidy.app"
    echo " Możesz uruchomić aplikację poleceniem: open dist/Tidy.app"
    echo "=========================================================="
else
    echo "Błąd: Nie znaleziono zbudowanej aplikacji w $APP_PATH"
    exit 1
fi
