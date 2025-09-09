#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <mod-id>"
    exit 1
fi

MOD_LIST_FILE="/home/arma3server/mods/modlist.txt"
source /home/arma3server/.bashrc

# The script needs a mod ID as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <mod-ID>"
    exit 1
fi

#search locally
name=$(grep $1 $MOD_LIST_FILE | cut -d '-' -f1)

# Defines the name of the HTML file to be processed
steam_mod_page="tempdown"
if [ -z "$name" ]; then

	curl "https://steamcommunity.com/sharedfiles/filedetails/?id=$1" -o "$steam_mod_page"
	# Gets the mod name from the HTML file
	name=$(grep -oP '<title>Steam Workshop::\K.*?(?=</title>)' "$steam_mod_page" || \
       grep -A1 "workshopItemTitle" "$steam_mod_page" | tail -n1 | sed 's/^[ \t]*//;s/[ \t]*$//')
fi
echo "Downloading mod: $name"
read -p "Confirm? (Y/N): " answer

# Handles user response
case "$answer" in
    [yY])
        echo "Starting download..."
        ;;
    [nN])
        echo "Download canceled."
        exit 1
        ;;
    *)
        echo "Invalid option. Download canceled."
        exit 1
        ;;
esac

rm $steam_mod_page
#set -x
steamcmd +force_install_dir /home/arma3server/mods +login $STEAM_USER +workshop_download_item 107410 $1 validate +exit;
echo -e "Download finished, please wait\n\n"

sleep 2

echo "Creating symbolic links"

rm -f "/home/arma3server/arma3/$1"
ln -s "/home/arma3server/mods/steamapps/workshop/content/107410/$1" /home/arma3server/arma3/;

echo "Finished"
