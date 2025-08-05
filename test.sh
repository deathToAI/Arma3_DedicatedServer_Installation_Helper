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
