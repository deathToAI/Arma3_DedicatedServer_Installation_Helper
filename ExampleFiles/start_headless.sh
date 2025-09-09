#!/bin/bash
set -x
steamcmd +login jogodetirinho +quit
set +x
MODS_DIR="/home/arma3server/mods/steamapps/workshop/content/107410"
cd /home/arma3server/
source ./mod_functions.sh
declare_mods

MODS_STRING=""
for mod_id in "${!mods_by_name[@]}"; do
    mod_folder=${mods_by_name[$mod_id]}
    MODS_STRING+="$mod_folder;"
done
mods=$MODS_STRING
mods=${MODS_STRING%;}
echo $mods

MOD_NAMES=""
for i in "${!mods_by_name[@]}"; do
       echo $i
        MODS_NAMES+="$i\n"
done

echo -e "Iniciado headless de Arma 3 com os mods:\n $MOD_NAMES"
#mods="\"$(ls /home/arma3server/mods/steamapps/workshop/content/107410/ | tr '\n' ';' | sed 's/;$//')\""
echo "Lista numerica de mods: $mods"
cd /home/arma3server/arma3/
echo "Iniciando o client headless"
set -x
/home/arma3server/arma3/arma3server_x64 -client -config=server.cfg -connect=127.0.0.1 -password=jogodep0wp0w -nosound -mod="$mods" 
