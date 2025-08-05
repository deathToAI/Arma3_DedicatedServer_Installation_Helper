#!/bin/bash
# Script para configurar servidor dedicado do Arma 3 em Linux(Ubuntu) puro
#Script for arma 3 server installation on barebones linux(Ubuntu)
#Mods downloading

#Setting of variables
install_dir="/home/arma3server/arma3"
mods_dir="/home/arma3server/mods/steamapps/workshop/content/107410/"
username=""
modlist="/home/arma3server/mods/modlist.txt"

#COLORS
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
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
    0-Exit
    1-Create 'arma3server' user
    2-Download steamcmd
    3-Insert Steam Account for mod Downloading (For mods to download you need a steam account with Arma 3 in library)
    4-Download Arma3 server
    5-Select directory for mods to download (Default: /home/arma3server/mods/steamapps/workshop/content/107410/)
    6-Download Mods
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
        read -rp "Enter mods directory path:(current $mods_dir) " mods_dir
     
        ;;
      ##Download Mods
      "6")
        echo -e "Option $option selected:  ${BOLD}${BLUE}Download Mods${NC}\n"
        read -rp "Enter mod ID or path to file with mod IDs: " mod_input
        add_mods "$mod_input"
        ;;
      *)
        echo -e "Invalid option, try again\n"
        sleep 0.5
        ;;
    esac
  done
    echo "Invalid option try againg"
    sleep 0.5
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
  echo ">> Converting files inside $mods_dir to ${YELLOW}lower case${NC}"
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
  # Ensure modlist.txt exists
  if [[ ! -f $modlist ]]; then
    echo 'Mod - Number' > "$modlist"
  fi

  # Helper to check if mod is already in list
  mod_in_list() {
    grep -q " - $1\$" "$modlist"
  }

  # Download and confirm function
  download_mod() {
    local id="$1"
    if curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=$id" -o steam_mod_page.html; then
      local name
      name=$(grep -oP '<title>Steam Workshop::\K.*?(?=</title>)' steam_mod_page.html || \
             grep -A1 "workshopItemTitle" steam_mod_page.html | tail -n1 | sed 's/^[ \t]*//;s/[ \t]*$//')
      rm -f steam_mod_page.html
      [[ -z "$name" ]] && name="Unknown"
      while true; do
        read -rp "Download mod $name (ID: $id)? (y/n):" key
        case "$key" in
          [yY])
            if ! mod_in_list "$id"; then
              echo "$name - $id" >> "$modlist"
            fi
            echo "Downloading $name..."
            steamcmd +force_install_dir /home/arma3server/mods +login $username +workshop_download_item 107410 $id +quit
            echo "Download finished."
            break
            ;;
          [nN])
            echo "Skipped $name."
            break
            ;;
          *)
            echo "Please enter 'y' or 'n'."
            ;;
        esac
      done
    else
      echo "Error fetching mod info for ID $id"
    fi
  }

  if [[ -f $mod_id ]]; then
    # It's a file with a list of mod IDs
    while IFS= read -r id; do
      [[ -z "$id" || "$id" =~ [^0-9] ]] && continue
      download_mod "$id"
    done < "$mod_id"
    echo "Mods list generated at $modlist!"
    cat "$modlist"
  elif [[ "$mod_id" =~ ^[0-9]+$ ]]; then
    # Single mod ID
    download_mod "$mod_id"
    echo "Mods list at $modlist:"
    cat "$modlist"
  else
    echo "Invalid mod ID or file."
  fi
ln -s "$mods_dir/*" $install_dir
echo ">> Creating mods symlinks from $mods_dir to $install_dir "
}

