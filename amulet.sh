#!/bin/bash

RESET="\e[0m" #Normal
BOLD="\033[1m" #Bold
BGND="\e[40m" #Background prefix
RED="${BOLD}${BGND}\e[1;91m" #Bold Red
GREEN="${BOLD}${BGND}\e[1;92m" #Bold Green
WHITE="${BOLD}${BGND}\e[1;97m" #Bold White

AFP="com.github.amulet_map_editor"
AFPR="https://github.com/EvilSupahFly/Amulet-Flatpak/releases/latest/download/amulet.flatpak"
AFPTD="/tmp/amulet-flatpak"

if flatpak list | grep -q "$AFP"; then
    echo -e "\n${GREEN}Launching Amulet...\necho -e \n${RESET}"
else
    mkdir $AFPTD
    echo -e "\n${RED}Amulet is not installed.\n${WHITE}Downloading and installing...\n"
    wget "$AFPR" --directory-prefix=$AFPTD -O amulet.flatpak
    flatpak install -u --assume-yes $AFPTD/amulet.flatpak
    echo -e "\n${WHITE}Cleaning up...\n"
    rm -f -R $AFPTD
    echo -e "\n${GREEN}Launching Amulet...\n${RESET}"
fi

flatpak run "$AFP"

