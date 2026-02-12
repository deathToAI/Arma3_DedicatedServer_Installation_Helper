#!/bin/bash
set -x
steamcmd +login $STEAM_USER +quit
set +x

cd /home/arma3server/

echo "=== Starting all Headless Clients ==="
echo "Importing functions.sh..."
source ./functions.sh
declare_mods

# Mostrar lista de mods carregados
MOD_NAMES=""
for i in "${!mods_by_name[@]}"; do
    echo $i
    MODS_NAMES+="$i\n"
done
echo -e "Arma 3 headless clients started with mods:\n $MOD_NAMES"

# Iniciar os 3 HCs com intervalo de 5 segundos
echo "Starting HC1..."
./hc1.sh &
sleep 5

echo "Starting HC2..."
./hc2.sh &
sleep 5

echo "Starting HC3..."
./hc3.sh &

echo "=== Todos Headless Clients iniciados! ==="