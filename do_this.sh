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
    ./flatpak-pip-generator --requirements-file=requirements.txt --yaml --output=amulet_map_editor

    # Create the initial header for our "proper" manifest
cat << EOL > "amulet.yml"
#### do_this.sh >>>
id: com.github.amulet_map_editor
name: Amulet Map Editor
runtime: org.freedesktop.Platform
runtime-version: '23.08'
sdk: org.freedesktop.Sdk//23.08

command: amulet_map_editor

finish-args:
  - --share=network
  - --share=ipc
  - --socket=fallback-x11
  - --socket=wayland
  - --device=dri
  - --filesystem=home:create
  - --talk-name=org.freedesktop.Notifications
  - --env=LIBGL_ALWAYS_SOFTWARE="0"
  - --env=OPENGL_VERSION=3.3
  - --env=OPENGL_LIB=/usr/lib/x86_64-linux-gnu/libGL.so
  - --env=PYTHON_VERSION=3.11.9
  - --env=WX_PYTHON=/app/lib/python3.11/site-packages/wx
  - --env=WX_PYTHON_VERSION=4.1.1
  - --env=XAPP_GTK3=true

modules:
  - shared-modules/SDL/SDL-1.2.15.json
  - shared-modules/SDL2/SDL2-with-libdecor.json
  - shared-modules/glew/glew.json
  - shared-modules/glu/glu-9.json
  - shared-modules/libappindicator/libappindicator-gtk3-introspection-12.10.json
  - shared-modules/gtk2/gtk2.json
  - shared-modules/dbus-glib/dbus-glib.json
  - shared-modules/pygame/pygame-1.9.6.json

#### <<< do_this.sh
EOL

    # Add the output from flatpak-pip-generator after cleaning up the temp file
    sed -i "s/modules://g" "amulet_map_editor.yaml"
    sed -i "s/name: amulet_map_editor//g" "amulet_map_editor.yaml"
    cat "amulet_map_editor.yaml" >> "amulet.yml"
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
    echo -e "exist, ${RED}this WILL all breakdown. ${GREEN}Buyer beware, right?${RESET}\n"
    exit 0
else
    echo -e "\n${YELLOW}    Skipping flatpak-pip-generator.${RESET}\n"
    sleep 3
fi

# Attempt to build Frankenstein's Monster - change "tag" when updating to newer Amulet versions
flatpak-builder -v --install-deps-from=flathub --mirror-screenshots-url=https://dl.flathub.org/media/ --add-tag=0.10.35 --bundle-sources --repo=amulet_flatpak_repo amulet_build_dir amulet.yml --force-clean

# Bundle the contents of the local repository into "amulet.flatpak"
flatpak build-bundle amulet_flatpak_repo amulet.flatpak com.github.amulet_map_editor

# Install bundle
echo -e "\n${YELLOW}    To install the Amulet Flatpak, type:"
echo -e "${WHITE}        flatpak install -u amulet.flatpak\n"

# Run bundle
echo -e "\n${YELLOW}    To run your install, type:"
echo -e "${WHITE}        flatpak run io.github.evilsupahfly.amulet-flatpak\n"

#Uninstall bundle if it doesn't work or you just don't need it
echo -e "\n${YELLOW}    To uninstall this, type:"
echo -e "${RED}        flatpak uninstall io.github.evilsupahfly.amulet-flatpak${RESET}\n"
