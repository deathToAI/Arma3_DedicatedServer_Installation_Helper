#!/bin/bash
set -x
steamcmd +login $STEAM_USER +quit
set +x
MODS_DIR="/home/arma3server/mods/steamapps/workshop/content/107410"
cd /home/arma3server/
source ./functions.sh
declare_mods

MODS_STRING=""
for mod_name in "${!mods_by_name[@]}"; do
    MODS_STRING+="@$mod_name;"
done
mods=$MODS_STRING
mods=${MODS_STRING%;}
echo $mods

MOD_NAMES=""
for i in "${!mods_by_name[@]}"; do
       echo $i
        MODS_NAMES+="$i\n"
done

echo -e "Arma 3 headless started with mods:\n $MOD_NAMES"
#mods="\"$(ls /home/arma3server/mods/steamapps/workshop/content/107410/ | tr '\n' ';' | sed 's/;$//')\""
echo "Numeric mod list: $mods"
cd /home/arma3server/arma3/
echo "Starting headless client"
set -x
/home/arma3server/arma3/arma3server_x64 -client -config=server.cfg -connect=127.0.0.1 -password=jogodep0wp0w -nosound -mod="$mods" 
