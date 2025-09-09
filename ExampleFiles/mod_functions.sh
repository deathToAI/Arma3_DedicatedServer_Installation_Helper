#!/bin/bash

# This file provides a function to declare a list of mods with their
# human-readable names and Steam Workshop IDs.
# It is intended to be sourced by other scripts, like 'start_server.sh',
# to easily manage which mods are loaded by the server.
# To use a mod, uncomment its line. To disable it, comment it out.

declare_mods(){
declare -gA mods_by_name=(
    [cba_a3]=450814997
    [ace]=463939057
    [suppress]=825174634
    [enhancedsoundscape]=825179978
    [dui_squad_radar]=1638341685
    [zeus_enhanced]=1779063631
    [digital_kompass]=2013447932
    [enhanced_movement_rework]=2034363662
    [arsenal_search]=2060770170
    [ride_where_you_look]=2153127400
    [braf]=2223739438
    [blastcore_murr_edition]=2257686620
  # [tier_one_weapons]=2268351256
    [enhanced_map]=2467589125
    [better_inventory]=2791403093
    [acstg_ai_cannot_see_through_grass]=2946868556
    [loot_to_vehicle]=2950537401
    [improved_game_sounds]=2995724580
    [antistasi_ultimate]=3020755032
)

# RHS Mods
#mods_by_name[rhs_afrf]=843425103
#mods_by_name[rhs_usf]=843577117
#mods_by_name[rhs_gref]=843593391
#mods_by_name[improved_game_sounds_rhs_compatibility]=3024724810
#mods_by_name[rhs_saf]=843632231

# 3CB Mods
#mods_by_name[uk3cb_baf_units_compat_ace]=1135539579
#mods_by_name[uk3cb_baf_factions]=893328083
#mods_by_name[uk3cb_baf_weapons]=893339590
#mods_by_name[uk3cb_baf_units]=893346105
#mods_by_name[uk3cb_baf_vehicles]=893349825

# CUP Mods
# Você pode descomentar estas linhas para adicionar os mods do CUP
mods_by_name[cup_weapons]=497660133
mods_by_name[cup_units]=497661914
mods_by_name[cup_vehicles]=541888371
#mods_by_name[cup_terrains_core]=583544987
#mods_by_name[cup_terrains_cwa]=853743366
#mods_by_name[cup_vehicle_extension]=3143649881

# Mods de Jogabilidade
mods_by_name[ace_no_medical]=3053169823
mods_by_name[enhanced_movement]=333310405
}
