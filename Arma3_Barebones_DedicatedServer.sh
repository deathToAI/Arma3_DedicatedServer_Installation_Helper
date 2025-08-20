#!/usr/bin/env bash
# Script para configurar servidor dedicado do Arma 3 em Linux(Ubuntu) puro
# Script for arma 3 server installation on barebones linux(Ubuntu)

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error when substituting.
# Pipelines return the exit status of the last command to exit with a non-zero status.
set -euo pipefail

echo "Setting Variables"
#Setting of variables
install_dir="/home/arma3server/arma3"
mods_base="/home/arma3server/mods"
mods_dir="/home/arma3server/mods/steamapps/workshop/content/107410/"
modlist="/home/arma3server/mods/modlist.txt"

#COLORS
RED='\033[0;31m'
ORANGE='\033[0;35m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
VIOLET='\033[1;35m'
BOLD='\033[1m'
NC='\033[0m'

main(){
  #Check if root
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please run with sudo or as root user."
    exit 1
  fi
  #Options Menu
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
      ##Create user arma3server if non existing  
      "1")
        echo -e "Option $option selected: ${BOLD}${BLUE}Create 'arma3server' user${NC}\n"
        create_arma3user
        ;;
      ##Download steamcmd if not downloaded
      "2")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Download steamcmd${NC}\n"
        download_steamcmd
        ;;
      ##Insert Steam Account for mod Downloading
      "3")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Insert Steam Account for mod Downloading${NC}(For mods to download you need a steam account with Arma 3 in library)\n"
        read -rp "Enter Steam username: " username
        # Ensure arma3server home exists and set ownership
        mkdir -p /home/arma3server
        chown arma3server:arma3server /home/arma3server
        echo "username=\"$username\"" > "/home/arma3server/.steamuser"
        chown arma3server:arma3server "/home/arma3server/.steamuser"
        sudo -u arma3server steamcmd +login "$username" +quit
        ;;
      ##Download Arma3 server
      "4")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Download Arma3 server${NC}\n"
        download_arma_server
        ;;
      #Convert mod files to lowercase
      "5")
        echo -e "Option $option selected:  ${BOLD}${VIOLET}Convert mod files to lowercase${NC}\n"
        tolowercase
        ;;  
      ##Download Mods
      "6")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Download Mods${NC}\n"
        add_mods 
        ;;
      ##Create systemd service and startup script
      "7")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Create systemd service and startup script${NC}\n"
        create_service
        ;;
      #Invalid option handling  
      *)
        echo -e "Invalid option, try again\n"
        sleep 0.5
        ;;
    esac
  done
}

#Create dedicated user for arma3server
create_arma3user(){
  if id "arma3server" &>/dev/null; then
    echo ">> User 'arma3server' already exists. Skipping."
  else
    echo ">> Creating user 'arma3server'"
    # No password needed for a service account, login is disabled.
    adduser --disabled-login --gecos "" arma3server
    echo ">> User 'arma3server' created."
  fi
  
  echo ">> Creating directories and setting permissions..."
  # Create directories and set ownership at the same time
  install -d -o arma3server -g arma3server "$install_dir" "$mods_base"
  echo ">> Directories created successfully."
}

#Install steamcmd
download_steamcmd(){
  echo ">> Installing dependencies"
  add-apt-repository multiverse
  dpkg --add-architecture i386
  apt update
  apt install -y lib32gcc-s1 lib32stdc++6 curl wget unzip tar

  echo ">> Installing SteamCMD"
  apt install -y steamcmd
}
#Download Arma 3 Server
download_arma_server(){
  echo ">> Downloading Arma 3 server"
  if [[ ! -f "/home/arma3server/.steamuser" ]]; then
      echo -e "${RED}Error: Steam username not set. Please run option 3 first.${NC}"
      return 1
  fi
  source "/home/arma3server/.steamuser"
  sudo -u arma3server steamcmd +force_install_dir "$install_dir" +login "$username" +app_update 233780 validate +quit
  echo "Default install dir: ${install_dir}"
}
##Due to linux behaviour when running arma 3 server the mods files must be converted to lower case(i don´t know, ask the arma3 devs)
tolowercase(){
  echo "Due to linux behaviour when running arma 3 server the mods files must be converted to lower case."
  echo -e ">> Converting files and directories inside ${VIOLET}${mods_dir}${NC} to ${BOLD}lower case${NC}"
  echo "This may take a while depending on the number of mods and files..."
  # This is much more efficient than the previous version.
  # It finds all files and directories with uppercase letters and renames them from the deepest level upwards.
  sudo -u arma3server find "$mods_dir" -depth -name '*[A-Z]*' -exec bash -c 'mv -v "$1" "$(dirname "$1")/$(basename "$1" | tr "A-Z" "a-z")"' _ {} \;
  echo -e "${GREEN}>> Conversion complete.${NC}"
}
add_mods(){
  # Ensure modlist passed exists
  if [[ ! -f $modlist ]]; then
    echo 'Mod - Number' > "$modlist"
    echo -e "${GREEN}Updated mod list at ${modlist}${NC}\n"
  fi

  #Show installed mods
  if [ -d "$mods_dir" ] && [ "$(ls -A $mods_dir)" ]; then
    echo ">> Checking for existing mods..."
    for id in $(ls -1 "$mods_dir"); do
      name=$(curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=${id}"|grep -oP '<title>Steam Workshop::\K.*?(?=</title>)')
      echo -e "   - ${name:-Unknown} ($id)"
    done
  fi
  #Prompt for mod ID or file with mod IDs
  echo -e "Enter mod ID or path to file with mod IDs(${BOLD}One id per line):\n Or press 0 to go back to options\n"
  read mod_input
  #If user pressed 0 go back to options
  if [[ "$mod_input" == "0" ]]; then
    echo -e "Going back to options...\n"
    return 0
  fi
  # Helper to check if mod is already in list
  mod_in_list() {
    grep -q " - $1\$" "$modlist"
  }
  # Check if mod_input is a file or a single ID
  #If mod a single id
  if [[ "$mod_input" =~ ^[0-9]+$ && ! -f "$mod_input" ]]; then
    source "/home/arma3server/.steamuser"
    # Check if mod is already in the list, if it is go back to options
    if mod_in_list "$mod_input"; then
      echo -e "Mod $mod_input already downloaded\n\n"
      return 0
    fi
    #If not on list and mod_input is a single id download mod
    name=$(curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=${mod_input}"|grep -oP '<title>Steam Workshop::\K.*?(?=</title>)')
    
    #Name handling
    [[ -z "$name" ]] && name="Unknown"
    echo "Downloading mod: $name with ID: $mod_input"
    #Download mod and adds to installed mods list
    sudo -u arma3server steamcmd +force_install_dir "$mods_base" +login "$username" +workshop_download_item 107410 "$mod_input" +quit
    echo "$name - $mod_input" >> "$modlist"
    echo "Mods list at $modlist:"

  #If mod_input is a file with mod IDs
  elif [[ -f $mod_input ]]; then 
      source "/home/arma3server/.steamuser"
      for id in $(grep -oE '^[0-9]+' "$mod_input"); do
        name=$(curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=$id"|grep -oP '<title>Steam Workshop::\K.*?(?=</title>)')
        [[ -z "$name" ]] && name="Unknown"
        if ! mod_in_list "$id"; then
          echo "Downloading mod: $name with ID: $id"
          echo "$name - $id" >> "$modlist"
          sudo -u arma3server steamcmd +force_install_dir "$mods_base" +login "$username" +workshop_download_item 107410 "$id" +quit
        else
          echo "Mod ${name} is already in the list, skipping."
        fi
      done
  else
      echo -e "${RED}Invalid mod ID or file path.${NC}"
  fi
  # Automatically convert to lowercase after downloading
  tolowercase

}

# Creates a systemd service and startup script for the Arma 3 dedicated server, including profile setup.
create_service(){
  if [[ ! -f "/home/arma3server/.steamuser" ]]; then
    echo -e "${RED}Error: Steam username not set. Please run option 3 first.${NC}"
    return 1
  fi
echo ">> Creating start_server.sh script at /home/arma3server/"
cat <<'EOF' | tee /home/arma3server/start_server.sh
#!/bin/bash

set -x
if [ -f /home/arma3server/.steamuser ]; then
  source /home/arma3server/.steamuser
else
  echo "Steam username file not found. Please run the setup script and set the Steam username."
  exit 1
fi
steamcmd +login $username +quit

cd /home/arma3server/arma3

lista=$(cat /home/arma3server/mods/modlist.txt)
echo -e "Initializing Arma 3 server with mods:\n\$lista"
mods=$(find /home/arma3server/mods/steamapps/workshop/content/107410/ -mindepth 1 -maxdepth 1 -type d | tr '\n' ';' | sed 's/;$//')

/home/arma3server/arma3/arma3server_x64 -name=profile1 -config=server.cfg -cfg=performance.cfg -limitFPS=700 -enableHT -loadMissionToMemory -autoInit -hugepages -noLogs -mod="$mods"

EOF
  echo ">> Setting execute permissions for start_server.sh"
  chmod +x /home/arma3server/start_server.sh
  chown arma3server:arma3server /home/arma3server/start_server.sh

#Creating profile1 directory
  echo ">> Creating profile1 directory"
  sudo -u arma3server mkdir -p '/home/arma3server/.local/share/Arma 3 - Other Profiles/profile1'
cat <<EOF | tee '/home/arma3server/.local/share/Arma 3 - Other Profiles/profile1/profile1.Arma3Profile'
version=1;
blood=1;
singleVoice=0;
gamma=1;
brightness=1;
soundEnableEAX=1;
soundEnableHW=0;
difficulty="Custom";
class DifficultyPresets
{
  class CustomDifficulty
  {
    class Options
    {
      reducedDamage=0;
      groupIndicators=2;
      friendlyTags=2;
      enemyTags=0;
      detectedMines=1;
      commands=1;
      waypoints=1;
      weaponInfo=2;
      stanceIndicator=1;
      staminaBar=0;
      weaponCrosshair=1;
      visionAid=0;
      thirdPersonView=1;
      cameraShake=0;
      scoreTable=1;
      deathMessages=1;
      vonID=1;
      mapContent=1;
      autoReport=0;
      multipleSaves=1;
      tacticalPing=2;
    };
    aiLevelPreset=3;
  };
  class CustomAILevel
  {
    skillAI=0.60000002;
    precisionAI=0.15000001;
  };
};

volumeCD=5;
volumeFX=5;
volumeSpeech=5;
volumeVoN=5;
volumeMapDucking=1;
volumeUI=1;
EOF
  chown -R arma3server:arma3server '/home/arma3server/.local'

#Create systemd service
echo ">> Creating systemd service for Arma 3 server"
cat <<EOF | tee /etc/systemd/system/arma3server.service
[Unit]
Description=Arma 3 Dedicated Server
After=network.target

[Service]
User=arma3server
Group=arma3server
Type=simple
ExecStart=/home/arma3server/start_server.sh
Restart=always
RestartSec=10
StartLimitInterval=300
StartLimitBurst=5

[Install]
WantedBy=multi-user.target

EOF
  echo ">> Reloading systemd daemon"
  systemctl daemon-reload
  echo ">> Enabling arma3server service"
  systemctl enable arma3server
  echo ">> Starting arma3server service"
  systemctl start arma3server
}
#Main function call
main