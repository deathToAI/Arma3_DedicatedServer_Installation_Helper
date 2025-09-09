#!/bin/bash

echo "Removendo mod"
set -x
rm -rf /home/arma3server/mods/steamapps/workshop/content/107410/$1
set +x
echo "Removendo link simbolico"
set -x
rm -r /home/arma3server/arma3/$1
set +x
echo "Finalizado"
