#!/bin/bash

RESET="\033[0m" #Normal
BOLD="\033[1m" #Bold
#BGND="\033[40m" #Background prefix
RED="${BOLD}\033[1;91m" #Bold Red
GREEN="${BOLD}\033[1;92m" #Bold Green
WHITE="${BOLD}\033[1;97m" #Bold White

AFP="com.github.amulet_map_editor"
AFPR="https://github.com/EvilSupahFly/Amulet-Flatpak/releases/latest/download/amulet-x86_64.flatpak"
AFPTD="/tmp/amulet-flatpak"

# Check if Flathub is installed at the user level
echo -e "${WHITE}Checking for Flathub...\n"
if ! flatpak remote-list --user | grep -q "flathub"; then
    echo -e "${RED}Flathub is not installed. ${WHITE}Attempting to add Flathub repository...\n"
    if ! flatpak remote-add --if-not-exists --user --assume-yes flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        echo -e "${RED}Flathub repository couldn't be added."
        echo -e "Did you install the flatpak base with your system package manager yet?\n${RESET}"
        exit 1
    else
        echo -e "${GREEN}Flathub repository added successfully.${RESET}\n"
    fi
else
    echo -e "${GREEN}Flathub already installed.\n"
fi

echo -e "${WHITE}Checking for Amulet...\n"

if flatpak list | grep -q "$AFP"; then
    echo -e "${GREEN}Amulet installed. Launching...\n${RESET}"
else
    mkdir $AFPTD
    echo -e "${RED}Amulet is not installed.\n${WHITE}Downloading and installing...\n"
    wget "$AFPR" --directory-prefix=$AFPTD -O amulet-x86_64.flatpak
    flatpak install -u --assume-yes $AFPTD/amulet-x86_64.flatpak
    echo -e "${WHITE}Cleaning up...\n"
    rm -f -R $AFPTD
    echo -e "${GREEN}Launching Amulet...\n${RESET}"
fi

flatpak run "$AFP"

