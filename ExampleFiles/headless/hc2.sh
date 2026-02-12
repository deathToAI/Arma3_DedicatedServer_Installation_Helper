#!/bin/bash
cd /home/arma3server/
source ./functions.sh
declare_mods

MODS_STRING=""
for mod_name in "${!mods_by_name[@]}"; do
    MODS_STRING+="@$mod_name;"
done
mods=${MODS_STRING%;}

echo "Starting Headless Client 2 (CPU 1)"
echo "Mods: $mods"
taskset -c 1 ./arma3server_x64 -client -config=server.cfg \
    -connect=127.0.0.1 -password=yourpassword -nosound \
    -mod="$mods" -name=HC2 -cpuCount=2 -exThreads=3