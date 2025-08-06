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

mods_base="/home/arma3server/mods"

#set -x
show_options(){
  read -p "Press the option number you want:
  0-Exit
  1-Create 'arma3server' user
  2-Download steamcmd
  3-Insert Steam Account for mod Downloading
  4-Select directory for mods to download
  5-Download Mods
  " option
}

echo -e "Existing mods in ${VIOLET}${mods_base} \n"

while true; do
	show_options
	case "$option" in
	"0")
	 echo "Exiting..."
	 sleep 1
	 break
	;;
	"1")
	 echo -e "Option $option selected \n"
	;;
	*)
	echo "Invalid option try againg"
	sleep 0.5
 esac
done
