#!/usr/bin/env bash
# Script for Arma 3 dedicated server installation on barebones Linux (Ubuntu)

# This script is a helper for Installing an Arma 3 server on a Linux(Ubuntu based) distro.
# It provides a menu-driven interface to perform setup tasks.


#Colors
RED='\033[0;31m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
VIOLET='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Source common variables and colors
source "$(pwd)/ExampleFiles/colors.sh"
source "$(pwd)/ExampleFiles/.creds.sh"
source "$(pwd)/ExampleFiles/functions.sh"


#Checks if curl is installed
if [ $(dpkg -l curl | grep -c "ok") -eq 0 ]; then
echo "Installing curl"
sudo apt install curl -y
else
echo "Curl is installed"
fi
#Check for net-tools(required for Arma)
if [ $(dpkg -l net-tools | grep -c "ok") -eq 0 ]; then
echo "Installing net-tools"
sudo apt install net-tools -y
else
echo "net-tools(ifconfig) is installed"
fi
#Check for steamcmd
if [ $(dpkg -l steamcmd | grep -c "ok") -eq 0 ]; then
    if [ $(cat /etc/issue | grep -c "Ubuntu") -eq 1  ];then
    sudo add-apt-repository multiverse; sudo dpkg --add-architecture i386; sudo apt update
    sudo apt install steamcmd
    
    elif [ $(cat /etc/issue | grep -c "Debian") -eq 1 ];then
    sudo apt update; sudo apt install software-properties-common; sudo apt-add-repository non-free; sudo dpkg --add-architecture i386; sudo apt update
    sudo apt install steamcmd

    else
    echo "Check https://developer.valvesoftware.com/wiki/SteamCMD for your distro/OS"
    fi

else
echo "Package steamcmd is installed"
fi

# Export variables to be available in sub-shells/scripts
steamuser_file="$(pwd)/ExampleFiles/.creds.sh"
export install_dir mods_base mods_dir modlist steamuser_file
export RED ORANGE YELLOW GREEN BLUE CYAN VIOLET BOLD NC

echo "This is a Helper for Installing an Arma 3 server on a Linux(Ubuntu based) distro"
echo "--------------------------------------------------------------------------------"
echo -e "For more info i highly suggest the user to ${RED}READ THE DOCUMENTATION ${NC}"
echo "--------------------------------------------------------------------------------"
echo "Github repository: https://github.com/deathToAI/Arma3_DedicatedServer_Installation_Helper"
echo -e "Also read the Arma 3 official docs at:\n
https://community.bistudio.com/wiki/Arma_3:_Server_Config_File#Mission_rotation \n
https://community.bistudio.com/wiki/server.armaprofile \n
https://community.bistudio.com/wiki/Arma_3:_Difficulty_Settings \n
"
# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error when substituting.
# Pipelines return the exit status of the last command to exit with a non-zero status.
set -euo pipefail

main(){
  # Check if running as root
  if [[ $EUID -ne 0 ]]; then
    echo -e "This script must be run as root. ${BOLD}Please run with sudo or as root user. ${NC}"
    exit 1
  fi
  # Options Menu
  show_options(){
    echo -e "Press the option number you want:\n
    ${RED}0-Exit${NC}
    ${GREEN}1-Create 'arma3server' user${NC}
    ${BLUE}2-Download steamcmd${NC}
    ${YELLOW}3-Insert Steam Account for mod Downloading (For mods to download you need a steam account with Arma 3 in library)${NC}
    ${ORANGE}4-Download Arma3 server${NC}
    ${VIOLET}5-Convert mod files to lowercase (Required for Linux servers)${NC}
    ${CYAN}6-Download Mods${NC}
    ${BOLD}7-Create systemd service${NC}
    "
    read -p "Option: " option
  }

  while true; do
    show_options
    case "$option" in
      "0")
        echo "Exiting..."
        echo "Remember to edit \n 
        $(readlink -f ExampleFiles/arma3server.service),\n
        $(readlink -f ExampleFiles/arma3headless.service) \n
        $(readlink -f ExampleFiles/.creds.sh)
        and $(readlink -f ExampleFiles/server.cfg) "
        sleep 1
        break
        ;;
      ## Create user arma3server if it doesn't exist
      "1")
        echo -e "Option $option selected: ${BOLD}${BLUE}Create 'arma3server' user${NC}\n"
        bash "ExampleFiles/create_user.sh"
        ;;
      ## Download steamcmd if not already downloaded
      "2")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Install steamcmd${NC}\n"
        sudo apt install steamcmd -y
        ;;
      ## Insert Steam Account for mod downloading
      "3")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Insert Steam Account for mod Downloading${NC}(For mods to download you need a steam account with Arma 3 in library)\n"
        read -rp "Enter Steam username: " username
        # Ensure arma3server home exists and set ownership
        mkdir -p /home/arma3server
        chown arma3server:arma3server /home/arma3server
        sed -i "s/^STEAM_USER=.*/STEAM_USER=\"$username\"/" "$steamuser_file"
        chown arma3server:arma3server "$steamuser_file"
        sudo -u arma3server steamcmd +login "$username" +quit
        ;;
      ## Download Arma 3 server
      "4")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Download Arma3 server${NC}\n"
        bash "ExampleFiles/download_server.sh"
        ;;
      # Convert mod files to lowercase
      "5")
        echo -e "Option $option selected:  ${BOLD}${VIOLET}Convert mod files to lowercase${NC}\n"
        tolowercase /home/arma3server/mods/steamapps/workshop/content/107410
        ;;  
      ## Download Mods
      "6")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Download Mods${NC}\n"
        apply_mods
        # After adding mods, it's good practice to update the list and convert to lowercase
        echo ">> Converting new mod files to lowercase..."
        tolowercase /home/arma3server/mods/steamapps/workshop/content/107410
        ;;
      ## Create systemd service and startup script
      "7")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Create systemd service and startup script${NC}\n"
        create_service
        ;;
      # Invalid option handling
      *)
        echo -e "Invalid option, try again\n"
        sleep 0.5
        ;;
    esac
  done
}

tolowercase(){
    DIR="${1:-.}"

  find "$DIR" -depth | while read -r item; do
      dir=$(dirname "$item")
      base=$(basename "$item")
      lower=$(echo "$base" | tr '[:upper:]' '[:lower:]')

      if [ "$base" != "$lower" ]; then
          if [ ! -e "$dir/$lower" ]; then
              mv -v "$item" "$dir/$lower"
          else
              echo "SKIP (already exists): $dir/$lower"
          fi
      fi
  done

}

create_service(){
     sudo cp ExampleFiles/arma3server.service /etc/systemd/system/arma3server.service
    sudo cp ExampleFiles/arma3headless.service /etc/systemd/system/arma3headless.service
    sudo systemctl daemon-reload
    sudo systemctl enable arma3server.service
    sudo systemctl enable arma3headless.service
    sudo systemctl start arma3server.service
    sudo systemctl start arma3headless.service
}


# Main function call
main