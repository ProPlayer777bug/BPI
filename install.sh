#!/bin/bash

# Default working directory for Pterodactyl
TARGET_DIR="/var/www/pterodactyl"

clear
echo "=============================================="
echo "       Pterodactyl Blueprint Auto-Installer   "
echo "=============================================="
echo ""

# Ensure script is run from or target directory exists
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR" || exit 1

# Check if Blueprint CLI exists
if ! command -v blueprint &> /dev/null; then
    echo "❌ ERROR: 'blueprint' CLI command is not installed."
    echo "Please install Blueprint framework first before running this installer."
    exit 1
fi

# Ask user for direct download link
read -p "Enter direct URL to .blueprint file: " BLUEPRINT_URL

if [ -z "$BLUEPRINT_URL" ]; then
    echo "❌ Error: URL cannot be empty."
    exit 1
fi

# Extract filename from URL
FILENAME=$(basename "$BLUEPRINT_URL" | cut -d'?' -f1)

# Ensure extension ends with .blueprint
if [[ "$FILENAME" != *.blueprint ]]; then
    FILENAME="${FILENAME}.blueprint"
fi

echo ""
echo "📥 Downloading: $FILENAME..."
echo "----------------------------------------------"

# Download file via curl or wget
if command -v curl &> /dev/null; then
    curl -sSL -o "$FILENAME" "$BLUEPRINT_URL"
elif command -v wget &> /dev/null; then
    wget -q -O "$FILENAME" "$BLUEPRINT_URL"
else
    echo "❌ ERROR: Neither 'curl' nor 'wget' was found on this system."
    exit 1
fi

# Validate download success
if [ ! -s "$FILENAME" ]; then
    echo "❌ Download failed or file is empty!"
    rm -f "$FILENAME"
    exit 1
fi

NAME="${FILENAME%.blueprint}"

echo "=============================================="
echo " 🚀 Installing extension: $NAME"
echo "=============================================="
echo ""

# Install via Blueprint CLI
if blueprint -install "$NAME"; then
    echo ""
    echo "✅ Successfully installed: $NAME"
    rm -f "$FILENAME"
else
    echo ""
    echo "❌ Installation failed for $NAME."
    exit 1
fi
