#!/bin/bash

source /home/arma3server/functions.sh
STEAM_USER=jogodetirinho
STEAM_PASS=jogodep0wp0w
declare_mods

set -x

core_priority=("cba_a3" "cup_terrains_core" "cup_terrains_maps")

# 2. Identify remaining mods to sort
mods_to_sort=()
for m in "${!mods_by_name[@]}"; do
    # Check if mod is not in core priority list
    is_core=false
    for core in "${core_priority[@]}"; do
        [[ "$m" == "$core" ]] && is_core=true && break
    done
    
    # If not core and not Antistasi (which must be last), add to sort
    if ! $is_core && [[ "$m" != "antistasi_ultimate" ]]; then
        mods_to_sort+=("$m")
    fi
done

# 3. Apply Stack Overflow solution
IFS=$'\n' sorted_secondary=($(sort <<<"${mods_to_sort[*]}"))
unset IFS

# 4. Reconstruct final order: CORE + SORTED + ANTISTASI
final_order=("${core_priority[@]}" "${sorted_secondary[@]}" "antistasi_ultimate")

# 5. Build final string for -mod parameter
mod_list=""
for mod_name in "${final_order[@]}"; do
    # Only add if mod is defined in mods_by_name array
    if [[ -n "${mods_by_name[$mod_name]}" ]]; then
        if [ -z "$mod_list" ]; then
            mod_list="@$mod_name"
        else
            mod_list="$mod_list;@$mod_name"
        fi
    fi
done

# initialize steamcmd runtime first
export STEAM_RUNTIME=1
export STEAM_COMPAT_CLIENT_INSTALL_PATH=$HOME/.steam/steam


export LD_LIBRARY_PATH=/home/arma3server/linux64:/home/arma3server/.steam/sdk64:/home/arma3server/.local/share/Steam/steamcmd/linux64:$LD_LIBRARY_PATH
export PATH=/sbin:/usr/sbin:$PATH
set -x
cd /home/arma3server/

./arma3server_x64 -name=profile1 -config=server.cfg -cfg=performance.cfg -limitFPS=700 -enableHT -loadMissionToMemory -autoInit  -noLogs -mod="$mod_list"
