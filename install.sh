#!/bin/bash

# Navigate to current directory
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" || exit 1

# Check for Blueprint CLI
if ! command -v blueprint &> /dev/null; then
    echo "❌ ERROR: 'blueprint' CLI command is not installed."
    exit 1
fi

# Detect all .blueprint files
shopt -s nullglob
BLUEPRINTS=( *.blueprint )

if [ ${#BLUEPRINTS[@]} -eq 0 ]; then
    echo "❌ No .blueprint files found in $(pwd)!"
    exit 1
fi

# Ensure whiptail is available for GUI menu
if ! command -v whiptail &> /dev/null; then
    apt-get update -y && apt-get install -y whiptail
fi

# Build GUI Menu Options
MENU_OPTIONS=("0" "⚡ INSTALL ALL (${#BLUEPRINTS[@]} total)")

for i in "${!BLUEPRINTS[@]}"; do
    MENU_OPTIONS+=("$((i + 1))" "${BLUEPRINTS[$i]}")
done

# Show Arrow-Key Terminal GUI
CHOICE=$(whiptail --clear --backtitle "Pterodactyl Blueprint GUI Installer" \
    --title " Select Blueprint " \
    --menu "Use UP/DOWN arrows and press ENTER:" 18 65 10 \
    "${MENU_OPTIONS[@]}" \
    3>&1 1>&2 2>&3)

# Exit if canceled
if [ $? -ne 0 ]; then
    clear
    echo "Cancelled."
    exit 0
fi

clear

# Function to execute installation automatically without prompting
install_file() {
    local file="$1"
    
    # Strip extension path cleanly
    local name
    name=$(basename "$file" .blueprint)

    echo "=============================================="
    echo " 🚀 Auto-Installing: $name"
    echo "=============================================="

    # Pipe 'yes' to bypass any interactive prompt inside Blueprint CLI
    if yes | blueprint -install "$name"; then
        echo ""
        echo "✅ Installed: $name"
        rm -f "$file"
    else
        echo ""
        echo "❌ Failed to install: $name"
        exit 1
    fi
    echo ""
}

# Run Installation based on selection
if [ "$CHOICE" -eq 0 ]; then
    for file in "${BLUEPRINTS[@]}"; do
        install_file "$file"
    done
    echo "=============================================="
    echo "✅ All blueprints installed successfully!"
    echo "=============================================="
else
    INDEX=$((CHOICE - 1))
    install_file "${BLUEPRINTS[$INDEX]}"
fi
