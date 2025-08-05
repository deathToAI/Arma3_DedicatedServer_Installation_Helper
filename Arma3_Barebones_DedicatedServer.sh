#!/bin/bash
# Script para configurar servidor dedicado do Arma 3 em Linux(Ubuntu) puro
#Script for arma 3 server installation on barebones linux(Ubuntu)
#Mods downloading

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color


main(){
  #Check if root
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please run with sudo or as root user."
    exit 1
  fi
show_options(){
  echo -e "Press the option number you want:\n
  0-Exit
  1-Create 'arma3server' user
  2-Download steamcmd
  3-Insert Steam Account for mod Downloading
  4-Select directory for mods to download
  5-Download Mods
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
    "1")
      echo -e "Option $option selected: ${BOLD}${BLUE}Create 'arma3server' user${NC}\n"
      create_arma3user
      ;;
    "2")
      echo -e "Option $option selected:  ${BOLD}${BLUE}Download steamcmd${NC}\n"
      download_steamcmd
      ;;
    "3")
      echo -e "Option $option selected:  ${BOLD}${BLUE}Insert Steam Account for mod Downloading${NC}\n"
      read -rp "Enter Steam username: " username
      ;;
    "4")
      echo -e "Option $option selected:  ${BOLD}${BLUE}Select directory for mods to download${NC}\n"
      read -rp "Enter mods directory path: " mods_dir
      ;;
    "5")
      echo -e "Option $option selected:  ${BOLD}${BLUE}Download Mods${NC}\n"
      read -rp "Enter mod ID or path to file with mod IDs: " mod_input
      add_mods "$mod_input"
      ;;
    *)
      echo "Invalid option, try again"
      sleep 0.5
      ;;
  esac
done
	echo "Invalid option try againg"
	sleep 0.5
 esac
done

#Options Menu

  ##Create user arma3server if non existing

  ##Download steamcmd if not downloaded

  ##Download Arma3 server

  ##Insert Steam Account for mod Downloading

  #Select directory for mods to download

  ##Download Mods
  add_mods();

}
mkdir -p /home/arma3server/mods
install_dir="/home/arma3server/arma3"
mods_dir="/home/arma3server/mods/steamapps/workshop/content/107410/"
username=""
modlist="/home/arma3server/mods/modlist.txt"
ln -s "$mods_dir;"* $install_dir


# 1. Create dedicated user for arma3server
create_arma3user(){
  echo ">> Creating 'arma3server'"
  echo "Do not forget to set arma3server a password with 'passwd arma3server' command"
  sudo adduser --disabled-password --gecos "" arma3server
}

# 2. Install 
download_steamcmd(){
  echo ">> Installing dependencies"
  sudo add-apt-repository multiverse
  sudo dpkg --add-architecture i386
  sudo apt update
  sudo apt install -y lib32gcc-s1 lib32stdc++6 curl wget unzip tar

  echo ">> Installing SteamCMD"
  sudo apt install -y steamcmd
}

download_arma_server(){
  echo ">> Downloading arma 3 server"
  sudo -u arma3server bash -c "steamcmd.sh +force_install_dir $install_dir +login $username +app_update 233780 validate +quit"
}

tolowercase(){
  # 5. Convert filename inside mod_dir to lowercase 
  ##Due to linux behaviour when running arma 3 server the mods files must be converted to lower case(i don´t know, ask the arma3 devs)
  echo ">> Criando script de renomeação para lowercase"
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
  local mod_id="$2"

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
}


# 6. Criar links simbólicos dos mods do Steam Workshop para a pasta do servidor
echo ">> Criando links simbólicos dos mods"
# Exemplo de onde estariam os mods:
STEAMMODS="/home/arma3server/mods/steamapps/workshop/content/107410"
TARGETDIR="/home/arma3server/arma3"


