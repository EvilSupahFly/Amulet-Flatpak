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
DEBUG=FALSE

lastword() {
    echo -e "\n${YELLOW}    To install or reinstall the Amulet Flatpak manually, type:"
    echo -e "${WHITE}        flatpak install -u amulet-x86_64.flatpak"
    echo -e "\n${YELLOW}    To run your installed flatpak manually, type:"
    echo -e "${WHITE}        flatpak run io.github.evilsupahfly.amulet-flatpak"
    echo -e "\n${YELLOW}    To uninstall the Amulet flatpak, type:"
    echo -e "${RED}        flatpak uninstall io.github.evilsupahfly.amulet-flatpak${RESET} \n"
}

# Function to report after process completions
report() {
    local status=$1 # F = failure, P = pass
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [[ "$status" == "F" ]]; then
        echo -e "\n${RED}[$timestamp] ERROR: $message\n${RESET}"
    elif [[ "$status" == "P" ]]; then
        echo -e "\n${WHITE}[$timestamp] SUCCESS: $message\n${RESET}"
    fi
}

function doFlatpakPIP {
    # Generate everything we need to build Amulet in the Flatpak sandbox
    if ! ./flatpak-pip-generator --requirements-file=requirements.txt --yaml --output=pip-gen; then
        ERR=$?
        report F "flatpak-pip-generator failed with error $ERR."
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

modules:
  - shared-modules/glew/glew.json
  - shared-modules/glu/glu-9.json
  - pip_gen.yaml

#### <<< do_this.sh
EOL

report P "flatpak-pip-generator succeeded!"
}

echo -e "${GREEN}"
clear

for arg in "$@"; do
    if [ "$arg" == "--do-pip" ]; then
        echo -e "\n${GREEN}    Proceeding with flatpak-pip-generator.${RESET}"
        sleep 1
        doFlatpakPIP
    elif [ "$arg" == "--help" ]; then
        echo -e "${GREEN}\nThis little script will build a local repository for the amulet-flatpak."
        echo -e "Upon completion, it assembles \"${WHITE}amulet.flatpak${GREEN}\" from the local repo."
        echo -e "\nYou can either run it like this:"
        echo -e "${YELLOW}    $0"
        echo -e "\n${GREEN}Or like this:"
        echo -e "${YELLOW}    $0 --do-pip"
        echo -e "\n${GREEN}\nRunning without ${WHITE}--do-pip${GREEN} will skip running"
        echo -e "${WHITE}flatpak-pip-generator${GREEN} to generate a new \"amulet.yml\"."
        echo -e "\nHowever, there's no error checking, so if ${WHITE}amulet.yml${GREEN} doesn't"
        echo -e "exist, ${RED}this WILL all breakdown. ${GREEN}Buyer beware, and all that jazz.\n"
        echo -e "\nYou can also specify ${WHITE}--auto${GREEN} and this script will also (try)"
        echo -e "to automatically install and run ${WHITE}amulet-x86_64.flatpak${GREEN} for you."
        echo -e "Limited error checking is included for each step so ${RED}if one step fails${GREEN},"
        echo -e "we won't just continue to ${RED}blindly muddle through${GREEN} to the next step and"
        echo -e "we will instead try to ${WHITE}exit gracefully.${RESET}\n"
        exit 0
    elif [ "$arg" == "--debug" ]; then
        DEBUG=TRUE
        echo -e "\n${WHITE}----------------------"
        echo -e "|${RED} DEBUG MODE ACTIVE. ${WHITE}|"
        echo -e "----------------------${RESET}\n"
    else
        echo -e "\n${YELLOW}    Skipping flatpak-pip-generator, starting ${WHITE}flatpak-builder${YELLOW}.${RESET}\n"
        sleep 1
    fi
done

# Attempt to build Frankenstein's Monster - change "tag" when updating to newer Amulet versions
echo -e "${WHITE}flatpak-builder -vvv --install-deps-from=flathub --mirror-screenshots-url=https://dl.flathub.org/media/ --add-tag=v0.10.35-beta --bundle-sources --repo=io.github.evilsupahfly.amulet-flatpak-repo amulet-flatpak_build_dir io.github.evilsupahfly.amulet-flatpak.yml --force-clean\n${GREEN}"
if ! flatpak-builder -vvv --install-deps-from=flathub --mirror-screenshots-url=https://dl.flathub.org/media/ --add-tag=v0.10.35-beta --bundle-sources --repo=io.github.evilsupahfly.amulet-flatpak-repo amulet-flatpak_build_dir io.github.evilsupahfly.amulet-flatpak.yml --force-clean; then
    ERR=$?
    report F "flatpak-builder failed with error $ERR."
    exit $ERR
fi

report P "flatpak-builder succeeded!"

# Bundle the contents of the local repository into "amulet-x86_64.flatpak"
echo -e "\n${WHITE}flatpak build-bundle -vvv io.github.evilsupahfly.amulet-flatpak-repo  io.github.evilsupahfly.amulet-flatpak${WHITE}\n"
if ! flatpak build-bundle -vvv io.github.evilsupahfly.amulet-flatpak-repo amulet-x86_64.flatpak io.github.evilsupahfly.amulet-flatpak; then
    ERR=$?
    report F "flatpak build-bundle failed with error $ERR."
    exit $ERR
fi

report P "flatpak build-bundle succeeded!"

for arg in "$@"; do
    if [ "$arg" == "--auto" ]; then
        # Install bundle
        echo -e "\n${YELLOW}    Installing bundle...\n${WHITE}"
        if ! flatpak install --include-sdk --include-debug -vvv -y -u amulet-x86_64.flatpak; then
            ERR=$?
            report F "flatpak install failed with error $ERR."
        else
            report P "flatpak install succeeded!"
        fi
        # Run bundle with optional output verbosity (-v, -vv, -vvv)
        if DEBUG=TRUE; then
            echo -e "\n${RED}    Running flatpak in debug mode...\n${WHITE}"
            echo -e "\n${YELLOW}    Once inside, type '${RED}python -vvv -m pdb -m amulet_map_editor${YELLOW}' to run Amulet though ${WHITE}PDB${YELLOW}.\n${WHITE}"
            flatpak-builder --run amulet-flatpak_build_dir io.github.evilsupahfly.amulet-flatpak.yml sh
            echo -e ${RESET}
            exit 0
        else
            echo -e "\n${YELLOW}    Running flatpak...\n${WHITE}"
            if ! flatpak run -vvv io.github.evilsupahfly.amulet-flatpak; then
                ERR=$?
                report F "Amulet crashed, reporting error $ERR."
            else
                report P "It works!"
            fi
            lastword
        fi
    fi
done
