#!/bin/bash

# Check if the script is running in a Python 3 virtual environment
#if [[ -z "$VIRTUAL_ENV" ]]; then
#    echo "Error: This script must be run inside a Python 3 virtual environment."
#    exit 1
#fi

B="\033[1m" #Bold or Hi-Intensty - depends on your terminal app
R="\e[0m" #Normal
#BGND="\e[40m" #Background
YLW="${B}\e[1;33m" #Bold/Hi-int Yellow
RED="${B}\e[1;91m" #Bold/Hi-int Red
GRN="${B}\e[1;92m" #Bold/Hi-int Green
WHT="${B}\e[1;97m" #Bold/Hi-int White
DEBUG=FALSE

doHelp() {
    echo -e "${GRN}\nThis little script will build a local repository for the amulet-flatpak."
    echo -e "Upon completion, it assembles \"${WHT}amulet.flatpak${GRN}\" from the local repo."
    echo -e "\nYou can run it like this:"
    echo -e "${YLW}    $0 --just-build"
    echo -e "\n${GRN}\nRunning ${WHT}--just-build${GRN} exits after building the flatpak and repo."
    echo -e "\n\n${YLW}    $0 --do-pip"
    echo -e "Without explicitly running with ${WHT}--do-pip${GRN} this will skip running"
    echo -e "${WHT}flatpak-pip-generator${GRN} to generate a new \"pip-gen.yaml\"."
    echo -e "\nHowever, if ${WHT}io.github.evilsupahfly.amulet-flatpak.yaml${GRN} or"
    echo -e "${WHT}pip-gen.yaml ${GRN}don't exist, ${RED}this WILL break. ${GRN}Buyer beware, and all that jazz.\n"
    echo -e "\n\n${YLW}    $0 --auto"
    echo -e "\nYou can also specify ${WHT}--auto${GRN} and this script will also (try)"
    echo -e "to automatically install and run ${WHT}amulet-x86_64.flatpak${GRN} for you."
    echo -e "Limited error checking is included for each step so ${RED}if one step fails${GRN},"
    echo -e "we won't just continue to ${RED}blindly muddle through${GRN} to the next step and"
    echo -e "we will instead try to ${WHT}exit gracefully."
    echo -e "\n\n${YLW}    $0 --debug"
    echo -e "\n${GRN}I've also included a ${WHT}--debug ${GRN}option to allow troubleshooting"
    echo -e "of the Amulet Flatpak ${YLW}inside ${GRN}the flatpak sandbox, if neccessary.${R}\n"
    echo -e "\n\n${YLW}    $0"
    echo -e "${YLW}    $0 --help"
    echo -e "${GRN}Running with no options or with ${WHT}--help${GRN} displays this help text.\n${R}"
}

lastword() {
    echo -e "\n${YLW}    To install or reinstall the Amulet Flatpak manually, type:"
    echo -e "${WHT}        flatpak install -u amulet-x86_64.flatpak"
    echo -e "\n${YLW}    To run your installed flatpak manually, type:"
    echo -e "${WHT}        flatpak run io.github.evilsupahfly.amulet-flatpak"
    echo -e "\n${YLW}    To uninstall the Amulet flatpak, type:"
    echo -e "${RED}        flatpak uninstall io.github.evilsupahfly.amulet-flatpak${R} \n"
}

# Function to report after process completions
report() {
    local status=$1 # F = failure, P = pass
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [[ "$status" == "F" ]]; then
        echo -e "\n${RED}[$timestamp] ERROR: $message\n${R}"
    elif [[ "$status" == "P" ]]; then
        echo -e "\n${WHT}[$timestamp] SUCCESS: $message\n${R}"
    fi
}

function doFlatpakPIP {
    # Generate everything we need to build Amulet in the Flatpak sandbox
    if ! ./flatpak-pip-generator --requirements-file=requirements.txt --yaml --output=pip-gen; then
        report F "flatpak-pip-generator failed."
        exit 1
    fi

    # Create the initial header for our "proper" manifest
cat << EOL > "io.github.evilsupahfly.amulet-flatpak.yaml"
#### do_this.sh >>>
id: io.github.evilsupahfly.amulet-flatpak
name: Amulet Map Editor
version: 0.10.36.01
runtime: org.freedesktop.Platform
runtime-version: '24.08'
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
  - --env=PYTHONDEBUG=3
  - --env=PYTHONVERBOSE=3
  - --env=PYTHONTRACEMALLOC=10

modules:
  - shared-modules/glew/glew.json
  - shared-modules/glu/glu-9.json
  - pip-gen.yaml
#  - name: python3-minecraft-resource-pack
#    buildsystem: simple
#    build-options:
#      build-args:
#        - --share=network
#    build-commands:
#      - pip3 install --verbose --no-index --find-links="file://\${PWD}"
#        --prefix=\${FLATPAK_DEST} "minecraft-resource-pack"
#        --report=pip_report.json --no-build-isolation
#    sources:
#      - type: file
#        path: minecraft_resource_pack-1.4.4+2.g8b81eba.dirty-py3-none-any.whl
#        sha256: 5f5bb5e97c1c117dfafc24f0cf88aa68b8d2f8f1dc07474b3ea6fe41021822fd

versioning:
  auto-increment: true
#### <<< do_this.sh
EOL

report P "flatpak-pip-generator succeeded!"
}

echo -e "\n${WHT}Colour ${YLW}Coding ${GRN}Active!\n"

# Check if Flathub is installed at the user level
echo -e "${WHT}Checking for Flathub...\n"
if ! flatpak remote-list --user | grep -q "flathub"; then
    echo -e "\n${RED}Flathub is not installed. ${WHT}Adding Flathub repository...\n"
    flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    echo "\n${GRN}Flathub repository added successfully.\n"
else
    echo "${GRN}Flathub repository already accessible."
fi

for arg in "$@"; do
    if [ "$arg" == "--do-pip" ]; then
        echo -e "\n${GRN}    Proceeding with flatpak-pip-generator.${R}\n"
        sleep 1
        doFlatpakPIP
    elif [[ -z "$arg" || "$arg" == "--help" ]]; then
        doHelp
        exit 0
    elif [ "$arg" == "--just-build" ]; then
        echo -e "\n${WHT}Skipping DEBUG and AUTO modes.\n"
        sleep 1
    elif [ "$arg" == "--debug" ]; then
        DEBUG=TRUE
        echo -e "\n${WHT}----------------------"
        echo -e "|${RED} DEBUG MODE ACTIVE. ${WHT}|"
        echo -e "----------------------${R}\n"
        sleep 1
    else
        echo -e "\n${YLW}    Skipping flatpak-pip-generator, starting ${WHT}flatpak-builder${YLW}.${R}\n"
        sleep 1
    fi
done

# Attempt to build Frankenstein's Monster - change "tag" when updating to newer Amulet versions
echo -e "${WHT}flatpak-builder -vvv --install-deps-from=flathub --mirror-screenshots-url=https://dl.flathub.org/media/ --add-tag=v0.10.36 --bundle-sources --repo=io.github.evilsupahfly.amulet-flatpak-repo amulet-flatpak_build_dir io.github.evilsupahfly.amulet-flatpak.yaml --force-clean\n${GRN}"
if ! flatpak-builder -vvv --install-deps-from=flathub --mirror-screenshots-url=https://dl.flathub.org/media/ --add-tag=v0.10.36 --bundle-sources --repo=io.github.evilsupahfly.amulet-flatpak-repo amulet-flatpak_build_dir io.github.evilsupahfly.amulet-flatpak.yaml --force-clean; then
    report F "flatpak-builder failed."
    exit $ERR
fi

report P "flatpak-builder succeeded!"

# Bundle the contents of the local repository into "amulet-x86_64.flatpak"
echo -e "\n${WHT}flatpak build-bundle -vvv io.github.evilsupahfly.amulet-flatpak-repo  io.github.evilsupahfly.amulet-flatpak${WHT}\n"
if ! flatpak build-bundle -vvv io.github.evilsupahfly.amulet-flatpak-repo amulet-x86_64.flatpak io.github.evilsupahfly.amulet-flatpak; then
    report F "flatpak build-bundle failed."
    exit $ERR
fi

report P "flatpak build-bundle succeeded!"

for arg in "$@"; do
    if [ "$arg" == "--auto" ]; then
        # Install bundle
        echo -e "\n${WHT}---------------------"
        echo -e "|${RED} AUTO MODE ACTIVE. ${WHT}|"
        echo -e "---------------------${R}\n"
        echo -e "\n${YLW}    Installing bundle...\n${WHT}"
        if ! flatpak install --include-sdk --include-debug -vvv -y -u amulet-x86_64.flatpak; then
            report F "flatpak install failed."
        else
            report P "flatpak install succeeded!"
        fi
        # Run bundle with optional output verbosity (-v, -vv, -vvv)
        if DEBUG=TRUE; then
            echo -e "\n${RED}    Running flatpak in debug mode...\n${WHT}"
            echo -e "\n${YLW}    Once inside, type '${RED}python -vvv -m pdb -m amulet_map_editor${YLW}' to run Amulet though ${WHT}PDB${YLW}.\n${R}\n"
            flatpak-builder --run amulet-flatpak_build_dir io.github.evilsupahfly.amulet-flatpak.yaml sh
            exit 0
        elif DEBUG=FALSE; then
            echo -e "\n${YLW}    Running flatpak...\n${WHT}"
            if ! flatpak run -vvv io.github.evilsupahfly.amulet-flatpak; then
                report F "Amulet crashed. Review Traceback logs for details."
            else
                report P "It works!"
            fi
            lastword
        fi
    fi
done

