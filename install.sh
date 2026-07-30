#!/bin/bash

# Default to current directory if script directory has no blueprints
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Check if blueprints exist in script dir; if not, check current working dir
shopt -s nullglob
BLUEPRINTS=( "$SCRIPT_DIR"/*.blueprint )

if [ ${#BLUEPRINTS[@]} -eq 0 ]; then
    BLUEPRINTS=( *.blueprint )
    if [ ${#BLUEPRINTS[@]} -gt 0 ]; then
        cd "$PWD" || exit 1
    fi
else
    cd "$SCRIPT_DIR" || exit 1
fi

clear

echo "=============================================="
echo "       Pterodactyl Blueprint Installer        "
echo "=============================================="
echo ""

if [ ${#BLUEPRINTS[@]} -eq 0 ]; then
    echo "❌ No .blueprint files found in $(pwd)!"
    echo "Please place your .blueprint files in this folder and try again."
    exit 1
fi

# Print menu options
echo "Select an option:"
echo "----------------------------------------------"
echo " [ 0] ⚡ INSTALL ALL BLUEPRINTS (${#BLUEPRINTS[@]} total)"
echo "----------------------------------------------"
for i in "${!BLUEPRINTS[@]}"; do
    filename="$(basename "${BLUEPRINTS[$i]}")"
    printf " [%2d] %s\n" "$((i + 1))" "$filename"
done
echo "----------------------------------------------"
echo ""

read -p "Enter selection (0-${#BLUEPRINTS[@]}): " CHOICE

# Input validation
if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 0 ] || [ "$CHOICE" -gt "${#BLUEPRINTS[@]}" ]; then
    echo ""
    echo "❌ Invalid selection. Please try again."
    exit 1
fi

# Check if Blueprint CLI exists
if ! command -v blueprint &> /dev/null; then
    echo ""
    echo "❌ ERROR: 'blueprint' CLI command is not installed."
    echo "Install Blueprint first, then run this installer again."
    exit 1
fi

# Option 0: Install ALL
if [ "$CHOICE" -eq 0 ]; then
    echo "=============================================="
    echo " 🚀 Starting batch installation..."
    echo "=============================================="
    echo ""

    for file in "${BLUEPRINTS[@]}"; do
        filename="$(basename "$file")"
        name="${filename%.blueprint}"

        echo "----------------------------------------------"
        echo "Installing: $name"
        echo "----------------------------------------------"

        if blueprint -install "$name"; then
            echo "✅ Installed: $name"
            rm -f "$file"
        else
            echo "❌ Failed to install: $name"
            echo "Stopping installer."
            exit 1
        fi

        echo ""
    done

    echo "=============================================="
    echo "✅ All blueprints installed successfully!"
    echo "=============================================="

# Single Blueprint Option
else
    SELECTED_FILE="${BLUEPRINTS[$((CHOICE - 1))]}"
    filename="$(basename "$SELECTED_FILE")"
    BLUEPRINT_NAME="${filename%.blueprint}"

    echo "=============================================="
    echo " 🚀 Installing target: $BLUEPRINT_NAME"
    echo "=============================================="
    echo ""

    if blueprint -install "$BLUEPRINT_NAME"; then
        echo "✅ Installation completed!"
        rm -f "$SELECTED_FILE"
    else
        echo "❌ Installation failed!"
        exit 1
    fi
fi
