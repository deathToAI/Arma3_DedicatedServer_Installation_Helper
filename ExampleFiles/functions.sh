$ cat functions.sh 
#!/bin/bash

#Key = name
#Value = number/ID
declare_mods(){
declare -gA mods_by_name=(
    [antistasi_ultimate]=3020755032
    [cba_a3]=450814997
    [zeus_enhanced]=1779063631

# Insert mods to be downloaded to your server here
[enhanced_soundscape]=825179978
[dui_squad_radar]=1638341685
[blastcore_murr_edition]=2257686620
[digital_kompass]=2013447932
[enhanced_map]=2467589125
[better_inventory]=2791403093
[acstg_ai_cannot_see_through_grass]=2946868556
[loot_to_vehicle]=2950537401
[ace]=463939057
[ace_no_medical]=3053169823
[arsenal_search]=2060770170
[dynamic_camo_system]=2800081814
[advanced_vault_system]=2794721649
[enhanced_move_rework]=2034363662
[simple_map_tools]=2013446344
[supress]=825174634
[tier1_weapons]=2268351256

#RHS
[rhsafrf]=843425103
[rhsusaf]=843577117
[rhsgref]=843593391
[rhssaf]=843632231
[team_map_intel]=3198265815
[rhs_improved_game_sounds]=3024724810
[improved_game_sounds]=2995724580
)
}

addmod(){
 
 local mod_id=$1
 local steam_mod_page="tempdown"
 local name=""
 
 # Fetch mod name from Steam
 name=$(curl -sL "https://steamcommunity.com/sharedfiles/filedetails/?id=$mod_id" | grep -oP '<title>Steam Workshop::\K.*?(?=</title>)' | sed 's/^[ \t]*//;s/[ \t]*$//')
 
 # Fallback in case grep fails
 if [ -z "$name" ]; then
   name="mod_$mod_id"
 fi
 
 echo "Starting mod download: $name (ID: $mod_id)"
 
 steamcmd +force_install_dir /home/arma3server/mods +login $STEAM_USER +workshop_download_item 107410 $mod_id validate +exit
 echo -e "Download finished, please wait\n\n"
 
 sleep 2
 
 echo "Creating symbolic links"
 final_mod_name=$(echo ${name,,}|tr "-" " " | tr " " "_" | tr '[:upper:]' '[:lower:]')
 target_link="/home/arma3server/@$final_mod_name"
 
 #set -x
 ln -sf /home/arma3server/mods/steamapps/workshop/content/107410/$mod_id "$target_link"
 cp  /home/arma3server/mods/steamapps/workshop/content/107410/$mod_id/keys/*.bikey /home/arma3server/keys/
 echo "Finished mod $name \n\n"
 
}
#Mods not declared in the array will be DELETED!!
clean_unused_mods() {
    local GAME_DIR="/home/arma3server/"
    echo "Cleaning unused mods"

    for pasta in "$GAME_DIR"/@*; do
        # Skip loop if there are no links or if it is not a symbolic link
        [ -L "$pasta" ] || continue

        # Extract mod name (remove @)
        local nome_limpo=$(basename "$pasta" | sed 's/^@//')

        # Check if name does NOT exist as key in associative array
        if [[ ! -v mods_by_name[$nome_limpo] ]]; then
            # Get real path of Workshop folder before removing link
            local caminho_real=$(readlink -f "$pasta")
            echo "Cleaning unused mod: $nome_limpo"
            echo " -> Deleting physical folder: $caminho_real"
            rm -rf "$caminho_real"  # Remove physical folder (numeric ID)
            echo " -> Deleting symbolic link: $pasta"
            rm -f "$pasta"
        fi
    done
    echo "Unused mods cleanup finished"
}

install_defined_mods() {
    for mod in "${!mods_by_name[@]}"; do
        echo "Name: $mod - ID:${mods_by_name[$mod]}\n"

        if [ -d "/home/arma3server/mods/steamapps/workshop/content/107410/${mods_by_name["$mod"]}" ];then
            echo "Mod $mod already installed\n"
        else
            addmod "${mods_by_name["$mod"]}"
        fi
    done
}

check_symlinks() {
    local GAME_DIR="/home/arma3server/"
    local WORKSHOP_DIR="/home/arma3server/mods/steamapps/workshop/content/107410"
    echo "--- Checking symbolic links integrity ---"

    for nome in "${!mods_by_name[@]}"; do
        local id=${mods_by_name[$nome]}
        local link_path="$GAME_DIR/@$nome"
        local real_path="$WORKSHOP_DIR/$id"

        if [ -d "$real_path" ]; then
            if [ ! -L "$link_path" ]; then
                echo "Missing link detected: @$nome (ID: $id). Creating symbolic link..."
                ln -sf "$real_path" "$link_path"
            else
                local destino_atual=$(readlink -f "$link_path")
                if [ "$destino_atual" != "$real_path" ]; then
                    echo "Incorrect link for @$nome. Correcting target..."
                    ln -sf "$real_path" "$link_path"
                fi
            fi
        else
            echo "ALERT: Mod @$nome (ID: $id) defined in array, but files not found in Workshop."
        fi
    done
}


tolowercase(){

# Base directory (current directory)
BASE="/home/arma3server/mods"
echo "Lowering case of files at $BASE"
# Rename deeper paths first to avoid breaking traversal
find "$BASE" -depth -print0 | while IFS= read -r -d '' item; do
    dir=$(dirname "$item")
    name=$(basename "$item")
    lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    # Only rename if the name actually changes
    if [[ "$name" != "$lower" ]]; then
        if [[ ! -e "$dir/$lower" ]]; then
            mv "$item" "$dir/$lower"
            echo "Renamed: $item -> $dir/$lower"
        else
            echo "Skipped (target exists): $dir/$lower"
        fi
    fi
done

}

apply_mods() {
    declare_mods
    clean_unused_mods
    install_defined_mods
    check_symlinks
    tolowercase
}

create_service(){
    set -x
    sudo cp ExampleFiles/arma3server.service /etc/systemd/system/arma3server.service
    sudo cp ExampleFiles/headless/arma3headless.service /etc/systemd/system/arma3headless.service
    sudo cp ExampleFiles/headless/* /home/arma3server/
    sudo cp ExampleFiles/start_server.sh /home/arma3server/
    sudo chmod +x /home/arma3server/*.sh
    sudo systemctl daemon-reload
    sudo systemctl enable arma3server.service
    sudo systemctl enable arma3headless.service
    sudo systemctl start arma3server.service
    sudo systemctl start arma3headless.service
    set +x
}