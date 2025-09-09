#!/usr/bin/env bash
# Script for Arma 3 dedicated server installation on barebones Linux (Ubuntu)

# This script is a helper for Installing an Arma 3 server on a Linux(Ubuntu based) distro.
# It provides a menu-driven interface to perform setup tasks.

# Source common variables and colors
source "ExampleFiles/config.sh"

# Export variables to be available in sub-shells/scripts
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
        bash "ExampleFiles/install_steamcmd.sh"
        ;;
      ## Insert Steam Account for mod downloading
      "3")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Insert Steam Account for mod Downloading${NC}(For mods to download you need a steam account with Arma 3 in library)\n"
        read -rp "Enter Steam username: " username
        # Ensure arma3server home exists and set ownership
        mkdir -p /home/arma3server
        chown arma3server:arma3server /home/arma3server
        echo "username=\"$username\"" > "$steamuser_file"
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
        bash "ExampleFiles/mods_to_lowercase.sh"
        ;;  
      ## Download Mods
      "6")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Download Mods${NC}\n"
        bash "ExampleFiles/add_mods.sh"
        # After adding mods, it's good practice to update the list and convert to lowercase
        echo ">> Updating modlist.txt..."
        bash "ExampleFiles/lister.sh"
        echo ">> Converting new mod files to lowercase..."
        bash "ExampleFiles/mods_to_lowercase.sh"
        ;;
      ## Create systemd service and startup script
      "7")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Create systemd service and startup script${NC}\n"
        bash "ExampleFiles/create_service.sh"
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