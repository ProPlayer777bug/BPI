#!/bin/bash

# Folder where blueprints will be saved
DOWNLOAD_DIR="./blueprints"

clear
echo "=============================================="
echo "    Pterodactyl Blueprint Auto-Downloader     "
echo "=============================================="
echo ""

# Check if Blueprint CLI exists
if ! command -v blueprint &> /dev/null; then
    echo "❌ ERROR: 'blueprint' CLI command is not installed."
    echo "Install Blueprint framework first, then run this installer again."
    exit 1
fi

mkdir -p "$DOWNLOAD_DIR"

# Step 1: Prompt for URL or direct file download
read -p "Enter direct URL to a .blueprint file (or press ENTER to use existing folder): " URL

if [ -n "$URL" ]; then
    FILENAME=$(basename "$URL" | cut -d'?' -f1)
    
    # Fix raw GitHub link if needed
    if [[ "$URL" == *"github.com"* ]] && [[ "$URL" == *"/blob/"* ]]; then
        URL=$(echo "$URL" | sed 's/github.com/raw.githubusercontent.com/' | sed 's//blob///')
    fi

    echo "📥 Downloading $FILENAME..."
    if command -v curl &> /dev/null; then
        curl -sSL -o "$DOWNLOAD_DIR/$FILENAME" "$URL"
    elif command -v wget &> /dev/null; then
        wget -q -O "$DOWNLOAD_DIR/$FILENAME" "$URL"
    fi
fi

# Step 2: Fetch all .blueprint files in directory
cd "$DOWNLOAD_DIR" || exit 1
shopt -s nullglob
BLUEPRINTS=( *.blueprint )

if [ ${#BLUEPRINTS[@]} -eq 0 ]; then
    echo ""
    echo "❌ No .blueprint files found in $(pwd)!"
    exit 1
fi

# Step 3: Present selection menu
echo ""
echo "=============================================="
echo "          Select Blueprint to Install         "
echo "=============================================="
echo " [ 0] ⚡ INSTALL ALL BLUEPRINTS (${#BLUEPRINTS[@]} total)"
echo "----------------------------------------------"
for i in "${!BLUEPRINTS[@]}"; do
    printf " [%2d] %s\n" "$((i + 1))" "${BLUEPRINTS[$i]}"
done
echo "----------------------------------------------"
echo ""

read -p "Enter selection (0-${#BLUEPRINTS[@]}): " CHOICE

# Input validation
if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 0 ] || [ "$CHOICE" -gt "${#BLUEPRINTS[@]}" ]; then
    echo ""
    echo "❌ Invalid selection."
    exit 1
fi

# Step 4: Installation execution
install_blueprint() {
    local file="$1"
    local name="${file%.blueprint}"

    echo "----------------------------------------------"
    echo " 🚀 Installing: $name"
    echo "----------------------------------------------"

    if blueprint -install "$name"; then
        echo "✅ Installed: $name"
        rm -f "$file"
    else
        echo "❌ Failed to install: $name"
        return 1
    fi
}

if [ "$CHOICE" -eq 0 ]; then
    echo ""
    echo "🚀 Starting batch installation of all blueprints..."
    for file in "${BLUEPRINTS[@]}"; do
        install_blueprint "$file" || exit 1
    done
    echo ""
    echo "✅ All blueprints installed successfully!"
else
    SELECTED_FILE="${BLUEPRINTS[$((CHOICE - 1))]}"
    echo ""
    install_blueprint "$SELECTED_FILE"
fi
