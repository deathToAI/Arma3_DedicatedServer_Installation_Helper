#!/bin/bash
# Script para configurar servidor dedicado do Arma 3 em Linux(Ubuntu) puro
#Mods downloading
add_mods(){

local username="$1"
local mod_id="$2"
# Mod directory 
mods_dir="/home/arma3server/mods/steamapps/workshop/content/107410/"

if [[ -f $mod_id ]]; then
echo 'Mod - Number' > /home/arma3server/mods/modlist.txt

# Loop through mod ID
for i in $(ls "$mods_dir"); do
    # Download through mod steampage
    if curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=$i" -o steam_mod_page.html; then
        # Extracts mod title workshopItemTitle)
        name=$(grep -oP '<title>Steam Workshop::\K.*?(?=</title>)' steam_mod_page.html || \
               grep -A1 "workshopItemTitle" steam_mod_page.html | tail -n1 | sed 's/^[ \t]*//;s/[ \t]*$//')

        #  No name found, uses "unknown"
        if [ -z "$name" ]; then
            name="Unknown"
        fi

        # Add list to file
        echo "$name - $i" >> /home/arma3server/mods/modlist.txt
    else
        echo "Error downloading mod $name" >> /home/arma3server/mods/modlist.txt
    fi
  done
#Removes temp file
rm -f steam_mod_page.html
echo "Mods list generated at /home/arma3server/mods/modlist.txt!"
cat /home/arma3server/mods/modlist.txt
fi


elif [[ "$mod_id" =~ ^[0-9]+$ ]];then 
  if curl -s "https://steamcommunity.com/sharedfiles/filedetails/?id=$mod_id" -o steam_mod_page.html; then
        # Extrai o nome do mod (do título ou da div workshopItemTitle)
        name=$(grep -oP '<title>Steam Workshop::\K.*?(?=</title>)' steam_mod_page.html || \
               grep -A1 "workshopItemTitle" steam_mod_page.html | tail -n1 | sed 's/^[ \t]*//;s/[ \t]*$//')
  rm -f steam_mod_page.html
  
  echo "Downloading mod: $name"
  while true; do
  read -rp "Wish to download this mod?(y/n)" key
    case "$key" in
    [yY])
      set -x
      steamcmd +force_install_dir /home/arma3server/mods +login $username +workshop_download_item $mod_id +quit
      set +x
      echo "Download finished, wait."
        
      sleep 2
      #Symlink creation
      echo "Creating symbolic liks"
      ln -s "$mods_dir/$mod_id /home/arma3server/arma3/"
      echo "Finalizado"
      break
      ;;
    [nN])
      echo "Cancelled by user"
      break
      ;;
    *)
      echo "Digite 's' para sim ou 'n' para não."
      ;;
    esac
  done
fi
}




set -e  # Encerra o script em qualquer erro

# 1. Criar usuário dedicado para o servidor
echo ">> Criando usuário 'arma3server'"
sudo adduser --disabled-password --gecos "" arma3server

# 2. Instalar dependências e SteamCMD
echo ">> Instalando dependências"
sudo add-apt-repository multiverse
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y lib32gcc-s1 lib32stdc++6 curl wget unzip tar

echo ">> Instalando SteamCMD"
sudo apt install -y steamcmd

# 3. Estrutura de pastas do servidor e mods
echo ">> Criando diretórios base"
sudo -u arma3server bash -c "
mkdir -p ~/arma3
mkdir -p ~/mods
"

# 4. Baixar o Arma 3 Dedicated Server via SteamCMD
echo ">> Baixando servidor dedicado do Arma 3"
sudo -u arma3server bash -c "steamcmd.sh +force_install_dir ~/arma3 +login anonymous +app_update 233780 validate +quit"

# 5. Script para converter nomes de arquivos e pastas para lowercase
echo ">> Criando script de renomeação para lowercase"
sudo -u arma3server bash -c "cd /home/arma3server/mods/steamapps/workshop/content/107410/;
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

# 6. Criar links simbólicos dos mods do Steam Workshop para a pasta do servidor
echo ">> Criando links simbólicos dos mods"
# Exemplo de onde estariam os mods:
STEAMMODS="/home/arma3server/mods/steamapps/workshop/content/107410"
TARGETDIR="/home/arma3server/arma3"

# Executar como usuário do servidor
sudo -u arma3server bash -c "
cd \$HOME
for mod in \$(${STEAMMODS}/*); do
    ln -s \"\$mod\" \"${TARGETDIR}/\$(basename \$mod)\"
done
"

echo ">> Instalação inicial concluída."
echo "Você pode executar tolowercase.sh após baixar mods para corrigir os nomes."
