#!/bin/bash

# Check if the script is running in a Python 3 virtual environment
#if [[ -z "$VIRTUAL_ENV" ]]; then
#    echo "Error: This script must be run inside a Python 3 virtual environment."
#    exit 1
#fi

BOLD="\033[1m" #Bold or Hi-Intensty - depends on your terminal app
RESET="\e[0m" #Normal
BGND="\e[40m" #Background
YELLOW="${BOLD}${BGND}\e[1;33m" #Bold/Hi-int Yellow
RED="${BOLD}${BGND}\e[1;91m" #Bold/Hi-int Red
GREEN="${BOLD}${BGND}\e[1;92m" #Bold/Hi-int Green
WHITE="${BOLD}${BGND}\e[1;97m" #Bold/Hi-int White


function doFlatpakPIP {
    # Generate everything we need to build Amulet in the Flatpak sandbox
    ./flatpak-pip-generator --requirements-file=requirements.txt --yaml --output=flatpak-pip-modules

    # Create the initial header for our "proper" manifest
cat << EOL > "io.github.evilsupahfly.amulet-flatpak.yml"
#### do_this.sh >>>
id: io.github.evilsupahfly.amulet-flatpak
name: Amulet Map Editor
runtime: org.freedesktop.Platform
runtime-version: '23.08'

command: amulet_map_editor

finish-args:
  - --share=network
  - --share=ipc
  - --socket=fallback-x11
  - --socket=wayland
  - --device=dri
  - --filesystem=home:create
  - --env=LIBGL_ALWAYS_SOFTWARE="0"
  - --env=OPENGL_VERSION=3.3
  - --env=OPENGL_LIB=/usr/lib/x86_64-linux-gnu/libGL.so

modules:
  - shared-modules/SDL/SDL-1.2.15.json
  - shared-modules/SDL2/SDL2-with-libdecor.json
  - shared-modules/glew/glew.json
  - flatpak-pip-modules.yaml
  - name: flatpak-pip-modules

#### <<< do_this.sh
EOL
}

if [[ "$1" == "do-pip" || "$1" == "-do-pip" || "$1" == "--do-pip" || "$1" == "-d" ]]; then
    echo -e "\n${GREEN}    Proceeding with flatpak-pip-generator.${RESET}"
    sleep 3
    doFlatpakPIP
elif [[ "$1" == "help" || "$1" == "--help" ]]; then
    echo -e "${GREEN}\nThis little script will build a local repository for the amulet-flatpak."
    echo -e "Upon completion, it assembles \"${WHITE}amulet.flatpak${GREEN}\" from the local repo."
    echo -e "\nYou can either run it like this:"
    echo -e "${YELLOW}    $0"
    echo -e "\n${GREEN}Or like this:"
    echo -e "${YELLOW}    $0 --do-pip"
    echo -e "\n${GREEN}\nRunning without ${WHITE}--do-pip${GREEN} will skip running"
    echo -e "${WHITE}flatpak-pip-generator${GREEN} to generate a new \"amulet.yml\"."
    echo -e "\nHowever, there's no error checking, so if ${WHITE}amulet.yml${GREEN} doesn't"
    echo -e "exist, ${RED}this WILL all breakdown. ${GREEN}Buyer beware, and all that jazz.${RESET}\n"
    exit 0
else
    echo -e "\n${YELLOW}    Skipping flatpak-pip-generator.${RESET}\n"
    sleep 3
fi

# Attempt to build Frankenstein's Monster - change "tag" when updating to newer Amulet versions
flatpak-builder -v --install-deps-from=flathub --mirror-screenshots-url=https://dl.flathub.org/media/ --add-tag=0.10.35 --bundle-sources --repo=io.github.evilsupahfly.amulet-flatpak-repo amulet-flatpak_build_dir io.github.evilsupahfly.amulet-flatpak.yml --force-clean

# Bundle the contents of the local repository into "amulet.flatpak"
flatpak build-bundle io.github.evilsupahfly.amulet-flatpak io.github.evilsupahfly.amulet-flatpak.flatpak io.github.evilsupahfly.amulet-flatpak

# Install bundle
echo -e "\n${YELLOW}    To install the Amulet Flatpak, type:"
echo -e "${WHITE}        flatpak install -u amulet.flatpak"

# Run bundle
echo -e "\n${YELLOW}    To run your install, type:"
echo -e "${WHITE}        flatpak run io.github.evilsupahfly.amulet-flatpak"

#Uninstall bundle if it doesn't work or you just don't need it
echo -e "\n${YELLOW}    To uninstall this, type:"
echo -e "${RED}        flatpak uninstall io.github.evilsupahfly.amulet-flatpak${RESET} \n"
