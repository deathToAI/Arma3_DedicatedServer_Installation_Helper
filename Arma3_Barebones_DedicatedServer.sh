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

# Function to check and install basic dependencies
install_dependency() {
    local pkg=$1
    if ! dpkg -l "$pkg" | grep -q "^ii"; then
        echo "Installing $pkg..."
        sudo apt install "$pkg" -y
    else
        echo "$pkg is already installed."
    fi
}

# 1. Install basic dependencies
install_dependency "curl"
install_dependency "net-tools"

# 2. Check for steamcmd
if ! dpkg -l steamcmd | grep -q "^ii"; then
    # Identify OS
    if [ -f /etc/os-release ]; then
        OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
    else
        echo "Error: /etc/os-release not found. Cannot identify OS."
        exit 1
    fi

    echo -e "\nSteamcmd is not installed. System identified as: $OS_ID\n"
    read -p "Do you want to proceed with installation? (y/n): " steamcmd_answer

    case "$steamcmd_answer" in
        [yY]|[yY][eE][sS])
            echo "Installing steamcmd..."
            
            if [ "$OS_ID" = "ubuntu" ]; then
                sudo add-apt-repository multiverse
                sudo dpkg --add-architecture i386
                sudo apt update
                sudo apt install -y steamcmd
            
            elif [ "$OS_ID" = "debian" ]; then
                sudo apt update
                sudo apt install -y software-properties-common
                sudo apt-add-repository non-free
                sudo dpkg --add-architecture i386
                sudo apt update
                sudo apt install -y steamcmd
            else
                echo "Unsupported Linux distribution: $OS_ID"
                echo "Check https://developer.valvesoftware.com/wiki/SteamCMD for your distro/OS"
                exit 1
            fi
            ;;
            
        [nN]|[nN][oO])
            echo "Installation cancelled by user."
            ;;
            
        *)
            echo "Invalid answer. Please run the script again and answer with Y or N."
            exit 1
            ;;
    esac
else
    echo "Package steamcmd is already installed."
fi


# Export variables to be available in sub-shells/scripts
steamuser_file="$(pwd)/ExampleFiles/.creds.sh"

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
    ${GREEN}1-Create 'arma3server' user ${NC}
    ${BLUE}2-Download Arma 3 Server ${NC}
    ${YELLOW}3-Download Arma 3 mods from Steam Workshop ${NC}
    ${ORANGE}4-Create systemd service and startup script ${NC}
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
        useradd -m -s /bin/bash "arma3server"
        echo "arma3server:arma3server" | chpasswd
        echo "User arma3server created sucessfully"
        ;;
      ## Download arma 3 server
      "2")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Insert Steam Account for mod Downloading${NC}(For mods to download you need a steam account with Arma 3 in library)\n"
        read -rp "Enter Steam username: " username
        # Ensure arma3server home exists and set ownership
        mkdir -p /home/arma3server
        chown arma3server:arma3server /home/arma3server
        cd /home/arma3server/
        sudo -u arma3server steamcmd +login "$STEAM_USER" app_update 233780 +quit
        echo "107410" > /home/arma3server/steam_appid.txt

        ;;
      
      "3") ## Download Arma 3 mods
        echo -e "Option $option selected:  ${BOLD}${BLUE}Download Arma3 server${NC}\n"
        read -p "Insert mod workshop ID" mod_id
        addmod $mod_id
        apply_mods
        ;;
     
      "4")## Create systemd service and startup script
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

# Main function call
main