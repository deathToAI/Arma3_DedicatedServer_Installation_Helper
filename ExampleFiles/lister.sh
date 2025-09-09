#!/bin/bash

set -euo pipefail

# This script lists installed mods, fetches their names from Steam Workshop,
# caches them, and generates a final modlist.txt.

# --- Configuration ---
MOD_NAMES_CACHE="/home/arma3server/mods/mod_names.txt"
MOD_LIST_OUTPUT="/home/arma3server/mods/modlist.txt"
MODS_DIR="/home/arma3server/mods/steamapps/workshop/content/107410/"

# --- Functions ---

get_mod_name() {
    local mod_id="$1"
    local mod_name

    # 1. Try to find the mod name in the local cache file
    mod_name=$(grep "^$mod_id=" "$MOD_NAMES_CACHE" | cut -d'=' -f2)

    if [ -z "$mod_name" ]; then
        # 2. If not found in cache, fetch it online
        echo "Fetching name for mod $mod_id online..." >&2
        
        # Fetch the name from the Steam page, decode HTML entities like '&amp;'
        mod_name=$(curl -sL "https://steamcommunity.com/sharedfiles/filedetails/?id=$mod_id" | \
                   grep -oP '<title>Steam Workshop::\K.*?(?=</title>)' | sed 's/&amp;/\&/g')

        # If not found, set to "Unknown"
        if [ -z "$mod_name" ]; then
            mod_name="Unknown"
        fi

        # 3. Add the newly found name to the cache file
        echo "$mod_id=$mod_name" >> "$MOD_NAMES_CACHE"
    fi
    echo "$mod_name"
}

# --- Main Logic ---

# Handle command-line arguments for specific actions
if [ "$#" -gt 0 ]; then
    case "$1" in
        --get-name)
            [ -z "$2" ] && echo "Usage: $0 --get-name <mod_id>" >&2 && exit 1
            get_mod_name "$2"
            exit 0
            ;;
    esac
fi

# Ensure cache file exists and is owned correctly
install -D -o arma3server -g arma3server /dev/null "$MOD_NAMES_CACHE"

# Start the output file
echo 'Mod - Numero' > "$MOD_LIST_OUTPUT"

# Loop through each downloaded mod directory
if [ ! -d "$MODS_DIR" ] || [ -z "$(ls -A "$MODS_DIR")" ]; then
    echo "No mods found in $MODS_DIR" >&2
    exit 0
fi

for mod_id in $(ls "$MODS_DIR"); do
    # Skip non-numeric directory names
    [[ ! "$mod_id" =~ ^[0-9]+$ ]] && continue

    mod_name=$(get_mod_name "$mod_id")

    # 4. Add the entry to the final output file
    echo "$mod_name - $mod_id" >> "$MOD_LIST_OUTPUT"
done

chown arma3server:arma3server "$MOD_LIST_OUTPUT"

echo "Mod list generated in modlist.txt!"
cat "$MOD_LIST_OUTPUT"
