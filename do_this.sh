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

# Function to report process errors
report_err() {
    echo -e "\n${RED}Error: $1${RESET}\n" >&2
}

# Function to report process errors
report_good() {
    echo -e "\n${GREEN}Congratulations! $1${RESET}\n"
}

function doFlatpakPIP {
    # Generate everything we need to build Amulet in the Flatpak sandbox
    if ! ./flatpak-pip-generator --requirements-file=requirements.txt --yaml --output=flatpak-pip-modules; then
        report_err "flatpak-pip-generator failed."
        exit 1
    fi

    # Create the initial header for our "proper" manifest
cat << EOL > "io.github.evilsupahfly.amulet-flatpak.yml"
#### do_this.sh >>>
id: io.github.evilsupahfly.amulet-flatpak
name: Amulet Map Editor
runtime: org.freedesktop.Platform
runtime-version: '23.08'
sdk: org.freedesktop.Sdk
command: amulet_map_editor

finish-args:
  - --device=all
  - --share=network
  - --share=ipc
  - --socket=fallback-x11
  - --socket=wayland
  - --filesystem=home:create
  - --talk-name=org.freedesktop.Notifications
  - --env=LIBGL_ALWAYS_SOFTWARE="0"
  - --env=OPENGL_VERSION=3.3
  - --env=OPENGL_LIB=/usr/lib/x86_64-linux-gnu/libGL.so
  - --env=XAPP_GTK3=true

modules:
  - shared-modules/glew/glew.json
  - shared-modules/glu/glu-9.json
  - pip_gen.yaml
  - resource_pack/resource_pack.yaml

#### <<< do_this.sh
EOL

report_good "flatpak-pip-generator succeeded!"
}

echo -e "${GREEN}"
clear

for arg in "$@"; do
    if [[ "$arg" == "do-pip" || "$arg" == "-do-pip" || "$arg" == "--do-pip" ]]; then
        echo -e "\n${GREEN}    Proceeding with flatpak-pip-generator.${RESET}"
        sleep 1
        doFlatpakPIP
    elif [[ "$arg" == "help" || "$arg" == "--help" ]]; then
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
        echo -e "\n${YELLOW}    Skipping flatpak-pip-generator, starting ${WHITE}flatpak-builder${YELLOW}.${RESET}\n"
        sleep 1
    fi
done

# Attempt to build Frankenstein's Monster - change "tag" when updating to newer Amulet versions
echo -e "${WHITE}flatpak-builder -vvv --install-deps-from=flathub --mirror-screenshots-url=https://dl.flathub.org/media/ --add-tag=0.10.35 --bundle-sources --repo=io.github.evilsupahfly.amulet-flatpak-repo amulet-flatpak_build_dir io.github.evilsupahfly.amulet-flatpak.yml --force-clean\n${RESET}"
if ! flatpak-builder -vvv --install-deps-from=flathub --mirror-screenshots-url=https://dl.flathub.org/media/ --add-tag=0.10.35 --bundle-sources --repo=io.github.evilsupahfly.amulet-flatpak-repo amulet-flatpak_build_dir io.github.evilsupahfly.amulet-flatpak.yml --force-clean; then
    report_err "flatpak-builder failed."
    exit 2
fi

report_good "flatpak-builder succeeded!"

# Bundle the contents of the local repository into "amulet.flatpak"
echo -e "\n${WHITE}flatpak build-bundle io.github.evilsupahfly.amulet-flatpak-repo amulet-x86_64.flatpak io.github.evilsupahfly.amulet-flatpak${WHITE}\n"
if ! flatpak build-bundle io.github.evilsupahfly.amulet-flatpak-repo amulet-x86_64.flatpak io.github.evilsupahfly.amulet-flatpak; then
    report_err "flatpak build-bundle faied."
    exit 3
fi

report_good "flatpak build-bundle succeeded!"

for arg in "$@"; do
    if [[ "$arg" == "auto" || "$arg" == "-auto" || "$arg" == "--auto" ]]; then
        # Install bundle
        echo -e "\n${YELLOW}    Installing bundle...\n${WHITE}"
        flatpak install -u amulet-x86_64.flatpak
        # Run bundle with optional output verbosity (-v, -vv, -vvv)
       echo -e "\n${YELLOW}    Running install...\n${WHITE}"
       flatpak run -vv io.github.evilsupahfly.amulet-flatpak
    else
        echo -e "\n${YELLOW}    To install the Amulet Flatpak, type:"
        echo -e "${WHITE}        flatpak install -u amulet-x86_64.flatpak"
        echo -e "\n${YELLOW}    To run your install, type:"
        echo -e "${WHITE}        flatpak run io.github.evilsupahfly.amulet-flatpak"
    fi
done

#Uninstall bundle if it doesn't work or you just don't need it
echo -e "\n${YELLOW}    To uninstall this, type:"
echo -e "${RED}        flatpak uninstall io.github.evilsupahfly.amulet-flatpak${RESET} \n"
