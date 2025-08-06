#!/bin/bash
# Script para configurar servidor dedicado do Arma 3 em Linux(Ubuntu) puro
#Script for arma 3 server installation on barebones linux(Ubuntu)
#Mods downloading

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
    5-Select directory for mods to download (Default: ${BOLD}/home/arma3server/mods/steamapps/workshop/content/107410/)
    ${CYAN}6-Download Mods${NC}
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
        steamcmd +login $username +quit
        ;;
      ##Download Arma3 server
      "4")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Download Arma3 server${NC}\n"
        download_arma_server
        ;;
      #Select directory for mods to download
      "5")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Select directory for mods to download${NC}\n"
        echo -e "Current mods directory: ${VIOLET}${mods_base}${NC}"
        read mods_base
        ;;
      ##Download Mods
      "6")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Download Mods${NC}\n"
        add_mods 
        ;;
      *)
        echo -e "Invalid option, try again\n"
        sleep 0.5
        ;;
    esac
  done
}

#Create dedicated user for arma3server
create_arma3user(){
  echo ">> Creating 'arma3server'"
  echo "Do not forget to set arma3server a password with 'passwd arma3server' command"
  sudo adduser --disabled-password --gecos "" arma3server
  su arma3user -c "mkdir -p ~/arma3"
  mkdir -p /home/arma3server/mods
}

#Install steamcmd
download_steamcmd(){
  echo ">> Installing dependencies"
  sudo add-apt-repository multiverse
  sudo dpkg --add-architecture i386
  sudo apt update
  sudo apt install -y lib32gcc-s1 lib32stdc++6 curl wget unzip tar

  echo ">> Installing SteamCMD"
  sudo apt install -y steamcmd
}
#Download Arma 3 Server
download_arma_server(){
  echo ">> Downloading Arma 3 server"
  if [[ -z "$username" ]]; then
    echo -e "${RED}Error: Steam username not set. Please run option 3 first.${NC}"
    return 1
  fi
  sudo -u arma3server bash -c "steamcmd.sh +force_install_dir $install_dir +login $username +app_update 233780 validate +quit"
  echo "Default install dir: $install_dir"
}
##Due to linux behaviour when running arma 3 server the mods files must be converted to lower case(i don´t know, ask the arma3 devs)
tolowercase(){
  echo "Due to linux behaviour when running arma 3 server the mods files must be converted to lower case(${BOLD}i dont know, ask the arma3 devs)"
  echo -e ">> Converting files inside ${VIOLET}${mods_dir}${NC} to ${BOLD}lower case"
  echo "This may take a while depending on the number of mods and files$"
  sudo -u arma3server bash -c "cd $mods_dir;
  depth=0
  for x in $(find . -type d | sed "s/[^/]//g"); do
    if [ ${depth} -lt ${#x} ]; then
      let depth=${#x}
    fi
  done;
  echo "Max depth: ${depth}"
  for ((i=1;i<=${depth};i++)); do
    for x in $(find . -maxdepth $i | grep [A-Z]); do
      mv "$x" "$(echo $x | tr 'A-Z' 'a-z')";
    done;
  done
  "
}
add_mods(){
  # Ensure modlist passed exists
  if [[ ! -f $modlist ]]; then
    echo 'Mod - Number' > "$modlist"
    echo -e "${GREEN}Updated mod list at ${modlist}"
  fi

  #Show installed mods
  for id in $(ls -1 "$mods_dir"); do
    name=$(curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=$id"|grep -oP '<title>Steam Workshop::\K.*?(?=</title>)')
    echo -e "Existing mods in $mods_dir $name - $id \n"
  done
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
  if [[ "$mod_input" =~ ^[0-9]+$ && ! -f $mod_input ]]; then
    # Check if mod is already in the list, if it is go back to options
    if mod_in_list "$mod_input"; then
      echo -e "Mod $mod_input already downloaded\n\n"
      return 0
    fi
    #If not on list and mod_input is a single id download mod
    name=$(curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=$mod_input"|grep -oP '<title>Steam Workshop::\K.*?(?=</title>)')
    
    #Name handling
    [[ -z "$name" ]] && name="Unknown"
    echo "Downloading mod: $name with ID: $mod_input"

    #Download mod and adds to installed mods list
    steamcmd +force_install_dir $mods_base +login $username +workshop_download_item 107410 $mod_input +quit
    echo "$name - $mod_input" >> "$modlist"
    echo "Mods list at $modlist:"

  #If mod_input is a file with mod IDs
  elif [[ -f $mod_input ]]; then 
      for id in $(grep -oE '^[0-9]+' "$mod_input"); do
        name=$(curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=$id"|grep -oP '<title>Steam Workshop::\K.*?(?=</title>)')
        [[ -z "$name" ]] && name="Unknown"
        if ! mod_in_list "$id"; then
          echo "Downloading mod: $name with ID: $id"
          echo "$name - $id" >> "$modlist"
          steamcmd +force_install_dir $mods_base +login $username +workshop_download_item 107410 $id +quit
        else
          echo "Mod $name is already in the list, skipping."
        fi
      done
  else
      echo "Invalid mod ID or file."
  fi
tolowercase
echo ">> Creating mods symlinks from $mods_dir to $install_dir "
ln -s $mods_dir/* $install_dir
}

main