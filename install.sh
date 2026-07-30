#!/bin/bash

# Folder containing blueprint files (defaults to current directory)
BLUEPRINT_DIR="$(pwd)"

cd "$BLUEPRINT_DIR" || exit 1

# Check if Blueprint CLI is installed
if ! command -v blueprint &> /dev/null; then
    echo "❌ ERROR: 'blueprint' CLI command is not installed."
    exit 1
fi

# Function to get all .blueprint files
get_blueprints() {
    shopt -s nullglob
    BLUEPRINTS=( *.blueprint )
}

get_blueprints

if [ ${#BLUEPRINTS[@]} -eq 0 ]; then
    echo "❌ No .blueprint files found in $(pwd)!"
    echo "Please place your .blueprint files in this directory."
    exit 1
fi

# Detect GUI tool (whiptail or dialog)
if command -v whiptail &> /dev/null; then
    GUI="whiptail"
elif command -v dialog &> /dev/null; then
    GUI="dialog"
else
    echo "⚠️ Neither 'whiptail' nor 'dialog' found. Installing whiptail..."
    apt-get update && apt-get install -y whiptail || yum install -y newt
    GUI="whiptail"
fi

# Build menu items array
MENU_OPTIONS=("ALL" "⚡ Install ALL Blueprints (${#BLUEPRINTS[@]} total)")

for i in "${!BLUEPRINTS[@]}"; do
    MENU_OPTIONS+=("$((i + 1))" "${BLUEPRINTS[$i]}")
done

# Show GUI Menu
CHOICE=$($GUI --clear --backtitle "Pterodactyl Blueprint GUI Installer" \
    --title " Select Blueprint to Install " \
    --menu "Use UP/DOWN arrows to select, then press ENTER:" 18 65 10 \
    "${MENU_OPTIONS[@]}" \
    3>&1 1>&2 2>&3)

# Exit if user cancelled
if [ $? -ne 0 ]; then
    clear
    echo "Cancelled."
    exit 0
fi

clear

# Installation helper
run_install() {
    local file="$1"
    local name="${file%.blueprint}"

    echo "=============================================="
    echo " 🚀 Installing: $name"
    echo "=============================================="

    if blueprint -install "$name"; then
        echo "✅ Installed: $name"
        rm -f "$file"
    else
        echo "❌ Failed to install: $name"
        exit 1
    fi
    echo ""
}

# Process Choice
if [ "$CHOICE" == "ALL" ]; then
    for file in "${BLUEPRINTS[@]}"; do
        run_install "$file"
    done
    echo "=============================================="
    echo "✅ All blueprints installed successfully!"
    echo "=============================================="
else
    INDEX=$((CHOICE - 1))
    SELECTED_FILE="${BLUEPRINTS[$INDEX]}"
    run_install "$SELECTED_FILE"
fi
