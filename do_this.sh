#!/bin/bash

# Check if the script is running in a Python 3 virtual environment
#if [[ -z "$VIRTUAL_ENV" ]]; then
#    echo -e "Error: This script must be run inside a Python 3 virtual environment."
#    exit 1
#fi

## Colour Definitions
NRM="\033[0m" # Normal
YLW="\033[1m\033[1;33m" # Yellow
RED="\033[1m\033[1;91m" # Red
GRN="\033[1m\033[1;92m" # Green
WHT="\033[1m\033[1;97m" # White
PRP="\033[1m\033[35m" # Magenta (Purple)

## Variable definitions
DEBUG=FALSE
SETVER=FALSE
DONE_PIP=FALSE
PIP_GEN=FALSE
AUTO=FALSE
AFPBASE="io.github.evilsupahfly.amulet_flatpak"
AFPREPO="${AFPBASE}-repo"
AFP_YML="${AFPBASE}.yaml"
AFP_XML="${AFPBASE}.metainfo.xml"

doHelp() {
    report N "${WHT}This helper script will build and run a version of the amulet-flatpak, among other things.\n"
    echo -e "${WHT}Upon completion, it assembles '${YLW}amulet-x86_64.flatpak${WHT}' from the local repo."
    echo -e "Options are as follows:"
    echo -e "\n${YLW}$0 --just-build"
    echo -e "${WHT}Running ${YLW}--just-build${WHT} exits after building the flatpak and repo and ${RED}can not ${WHT}be used in conjunction with any other option except ${YLW}--version${WHT}."
    echo -e "\n${YLW}$0 --do-pip"
    echo -e "Specifying ${WHT}--do-pip${WHT} will run ${GRN}flatpak-pip-generator${WHT} to generate a new 'pip-gen.yaml'. However, if ${RED}$AFP_YML${WHT} or ${RED}pip-gen.yaml ${WHT}don't exist, this ${RED}WILL${WHT} break things. This option is compatible with all other options except ${YLW}--just-build ${WHT}and ${YLW}--help${WHT}."
    echo -e "\n${YLW}$0 --version x.y.z.aa"
    echo -e "${WHT}Running ${WHT}--version ${WHT} will override the version number otherwise set by ${YLW}$AFP_YML${WHT}. Version numbers follow the same rules as Python for dotted decimals (i.e. 0.10.36 or 9.10.0.19), and this option is compatible with all other options except ${YLW}--just-build ${WHT}and ${YLW}--help${WHT}."
    echo -e "\n${YLW}$0 --auto"
    echo -e "${WHT}You can also specify ${YLW}--auto${WHT} and this script will also (try) to automatically install and run ${YLW}amulet-x86_64.flatpak${WHT} for you. Limited error checking is included for each step so ${RED}if one step fails${WHT},we'll try to exit gracefully. ${YLW}--auto${WHT} works with all options except ${YLW}--just-build ${WHT}and ${YLW}--help${WHT}."
    echo -e "\n${YLW}$0 --debug"
    echo -e "${WHT}I've also included a ${YLW}--debug ${WHT}option to allow troubleshooting of the Amulet Flatpak inside the flatpak sandbox, if neccessary. ${YLW}--debug ${WHT}compatible with all other options except ${YLW}--just-build ${WHT}and ${YLW}--help${WHT}."
    echo -e "\n${YLW}$0"
    echo -e "${YLW}$0 --help"
    echo -e "${WHT}Running with no options or with ${YLW}--help${WHT} displays this help text. When specifying ${YLW}--help${WHT}, all other options are ignored.${NRM}\n"
    lastWord
}

# Some parting words for future runs
lastWord(){
    report N "\n${WHT}--------------------------------------------------\n${WHT}| The last word and some help for terminal users |\n${WHT}--------------------------------------------------\n"
    echo -e "\n${WHT}To install or reinstall the Amulet Flatpak manually, type:"
    echo -e "${YLW}    flatpak install -u amulet-x86_64.flatpak"
    echo -e "\n${WHT}To run your installed flatpak manually, type:"
    echo -e "${YLW}    flatpak run $AFPBASE"
    echo -e "\n${WHT}To run the Amulet Flatpak manually in debug mode, type:"
    echo -e "${YLW}    flatpak-builder --run amulet-flatpak_build_dir $AFP_YML sh"
    echo -e "${WHT}Once inside the flatpak shell, type:"
    echo -e "${YLW}    python -vvv -m pdb -m amulet_map_editor"
    echo -e "\n${WHT}To uninstall the Amulet flatpak, type:"
    echo -e "${RED}    flatpak uninstall $AFPBASE \n"
    exit 0
}

# Function to report after process completions
report() {
    local status=$1 # F = failure, P = pass, N = notice (neutral)
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [[ "$status" == "F" ]]; then
        echo -e "\n${WHT}[$timestamp] ${RED}ERROR: ${WHT}$message\n${NRM}"
    elif [[ "$status" == "P" ]]; then
        echo -e "\n${WHT}[$timestamp] ${GRN}SUCCESS: ${WHT}$message\n${NRM}"
    elif [[ "$status" == "N" ]]; then
        echo -e "${WHT}[$timestamp] ${YLW}NOTICE: ${WHT}$message ${NRM}"
    fi
}

function doInstall {
    report F "${RED}$1 not found.\n${WHT}Checking distribution..."

    # Determine the distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        report P "${WHT}Attempting install for ${YLW}$DISTRO${WHT}..."; sleep 2
        echo
    fi

    # Determine the package manager and install appstreamcli
    case $DISTRO in
        ubuntu|debian)
            apt update && sudo apt install -y $1
            ;;
        fedora)
            sudo dnf install -y $1
            ;;
        centos|rhel)
            sudo yum install -y $1
            ;;
        arch)
            sudo pacman -Syu $1
            ;;
        *)
            report F "${RED}Unsupported distribution: $DISTRO. \n${WHT}Please manually install using your graphical package manager.\n${NRM}"
            exit 1
            ;;
    esac
}

function doFlatpakPIP {
    # Generate everything we need to build Amulet in the Flatpak sandbox
    if ! ./flatpak-pip-generator --requirements-file=requirements.txt --yaml --output=pip-gen; then
        report F "flatpak-pip-generator failed."
        exit 1
    fi

    # Create the initial header for our primary manifest
cat << EOL > "$AFP_YML"
#### Generated by do_this.sh >>>
id: $AFPBASE
name: Amulet Map Editor
#version: $AFP_VER
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
  - --filesystem=home:persistent
  - --filesystem=~/.cache:persistent
  - --filesystem=host:create
  - --env=LIBGL_ALWAYS_SOFTWARE="0"
  - --env=OPENGL_version 3.3
  - --env=OPENGL_LIB=/usr/lib/x86_64-linux-gnu/libGL.so
  - --env=PYTHONDEBUG=3
  - --env=PYTHONVERBOSE=3
  - --env=PYTHONTRACEMALLOC=10
# According to the official docs (https://docs.flatpak.org/en/latest/sandbox-permissions.html), the following directories are blacklisted:
# - /lib, /lib32, /lib64, /bin, /sbin, /usr, /boot, /root, /tmp, /etc, /app, /run, /proc, /sys, /dev, /var
# Meaning you can't give an app access to them even using the override method.
modules:
  - shared-modules/glew/glew.json
  - shared-modules/glu/glu-9.json
  - pip-gen.yaml
  - name: metainfo-xml
    buildsystem: simple
    build-commands:
      - install -Dm644 io.github.evilsupahfly.amulet_flatpak.metainfo.xml -t \${FLATPAK_DEST}/share/metainfo/
    sources:
      - type: file
        path: io.github.evilsupahfly.amulet_flatpak.metainfo.xml
  - name: metainfo-ico
    buildsystem: simple
    build-commands:
      - install -Dm644 io.github.evilsupahfly.amulet_flatpak.png -t \${FLATPAK_DEST}/share/icons/hicolor/256x256/apps/
    sources:
      - type: file
        path: io.github.evilsupahfly.amulet_flatpak.png
  - name: metainfo-desktop
    buildsystem: simple
    build-commands:
      - install -Dm755 io.github.evilsupahfly.amulet_flatpak.desktop -t \${FLATPAK_DEST}/share/applications/
    sources:
      - type: file
        path: io.github.evilsupahfly.amulet_flatpak.desktop
    # /AmuletMapEditor/resource_packs
  - name: vanilla-textures
    buildsystem: simple
    build-commands:
      - install -Dm644 vanilladefault_121.zip -t \${FLATPAK_DEST}/data/AmuletMapEditor/resource_packs/
    sources:
      - type: file
        path: vanilladefault_121.zip
#### <<< Generated by do_this.sh
EOL
report P "flatpak-pip-generator succeeded!"
DONE_PIP=TRUE
}

check_version() {
    local version="$1"
    if [[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        report P "Version ${GRN}$version${WHT} from ${YLW}command line ${WHT}being used.\n"
    else
        report F "'${RED}$version${WHT}' must be a dotted decimal number.\n"
        exit 1
    fi
}

report N "\n${WHT}--------------------------------\n${WHT}| ${RED}PRELIMINARY CHECKS INITIATED ${WHT}|\n${WHT}--------------------------------"
sleep 2

for arg in "$@"; do
    if [[ -z "$arg" || "$arg" == "--help" ]]; then
        doHelp
    fi
    case "$arg" in
        --version)
            shift
            AFP_VER="$1"
            check_version "$AFP_VER"
            shift
            ;;
        --help)
            doHelp
            ;;
        --do-pip)
            PIP_GEN=TRUE
            if [[ "$DONE_PIP" == "FALSE" ]]; then
                report N "${GRN}Proceeding with ${YLW}flatpak-pip-generator${GRN}....${NRM}"
                sleep 2
                doFlatpakPIP
            else
                report N "${YLW}flatpak-pip-generator ${RED}has already run.\n${YLW}Delete or rename the previous run's ${RED}pip-gen.yaml${YLW} before trying again.\n${WHT}Using existing ${RED}pip-gen.yaml${WHT} for this build."
            fi
            ;;
        --just-build)
            if [[ "$@" == *"--auto"* || "$@" == *"--debug"* ]]; then
                report N "${RED}Error: --just-build cannot be used with --auto, or --debug.${NRM}"
                exit 1
            fi
            report N "${WHT}Skipping ${RED}DEBUG ${WHT}and ${RED}AUTO ${WHT}modes."
            sleep 2
            ;;
        --debug)
            if [[ "$@" == *"--just-build"* ]]; then
                report N "${RED}Error: --debug cannot be used with --just-build.${NRM}"
                exit 1
            fi
            DEBUG=TRUE
            report N "\n${WHT}----------------------\n|${RED} DEBUG MODE ACTIVE. ${WHT}|\n${WHT}----------------------"
            sleep 2
            ;;
        --auto)
            if [[ "$@" == *"--just-build"* ]]; then
                report N "${RED}Error: --auto cannot be used with --just-build.${NRM}"
                exit 1
            fi
            AUTO=TRUE
            report N "\n${WHT}---------------------\n|${RED} AUTO MODE ACTIVE. ${WHT}|\n---------------------\n"
            ;;
    esac
done

if PIP_GEN=FALSE; then
    report N "${WHT}Skipping ${YLW}flatpak-pip-generator${WHT}, starting ${YLW}flatpak-builder${WHT}."
    sleep 2
fi

# Check if Flathub is installed at the user level
report N "${WHT}Checking for Flathub..."
if ! flatpak remote-list --user | grep -q "flathub"; then
    doInstall flatpak
    # Check if installation was successful
    if ! flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        report F "${RED}Flathub repository couldn't be added.${NRM}"
        exit 1
    else
        report P "${GRN}Flathub repository added successfully.${NRM}"
    fi
else
    report P "${GRN}Flathub already installed. ${WHT}Checking for updates..."; sleep 2
    flatpak update -y -u
    echo
fi

# Check if Flathub is installed at the user level
report N "${WHT}Checking for Flatpak Builder..."; sleep 2
if ! flatpak list | grep -q "org.flatpak.Builder"; then
    report F "${RED}Flatpak Builder not found. ${WHT}Attempting to install..."; sleep 2
    if ! flatpak install --user -y org.flatpak.Builder; then
        report F "${RED}Fatal Error: Flatpak Builder couldn't be installed."
        exit 1
    fi
else
    report P "${WHT}org.flatpak.Builder is present."; sleep 2
fi

# Check for AppStream (appstreamcli), install if it's missing
report N "${WHT}Checking for AppStream..."; sleep 2

if ! command -v appstreamcli &> /dev/null; then
    doInstall appstream
    # Check if installation was successful
    echo
    if ! command -v appstreamcli &> /dev/null; then
        report F "${RED}Installation via package manager failed. \n${WHT}Try installing manually.\n${NRM}"
        exit 1
    fi
else
    report P "${GRN}AppStream install verified.\n${NRM}"; sleep 2
fi

report N "\n${WHT}--------------------------------\n${WHT}|${RED} PRELIMINARY CHECKS COMPLETED ${WHT}|\n${WHT}--------------------------------"
sleep 2

# Attempt to build Frankenstein's Monster - change "tag" when updating to newer Amulet versions
report N "${WHT}flatpak-builder -vvv --user --install-deps-from=flathub --add-tag=$AFP_VER --bundle-sources --repo=$AFPREPO amulet-flatpak_build_dir $AFP_YML --force-clean\n${GRN}"
if ! flatpak-builder -vvv --user --install-deps-from=flathub --add-tag=$AFP_VER --bundle-sources --repo=$AFPREPO amulet-flatpak_build_dir $AFP_YML --force-clean; then
    report F "flatpak-builder failed. \n"
    exit 1
fi

report P "flatpak-builder succeeded! \n"

# Bundle the contents of the local repository into "amulet-x86_64.flatpak"
if ! flatpak build-bundle -vvv $AFPREPO amulet-x86_64.flatpak $AFPBASE; then
    report F "flatpak build-bundle failed.\n"
    exit 1
fi

report P "flatpak build-bundle succeeded! \n"
# Install bundle
report N "${YLW}Installing bundle..."

if AUTO=TRUE; then
    report N "\n${WHT}---------------------\n|${RED} AUTO MODE ACTIVE. ${WHT}|\n---------------------\n"
    report N "${WHT}Removing old flatpak version, and installing the new one...${NRM}\n"
    flatpak --user uninstall -y amulet
    if DEBUG=TRUE; then
        if ! flatpak install --include-sdk --include-debug -vvv -y -u amulet-x86_64.flatpak; then
            report F "flatpak install failed. \n"
            exit 1
        else
            report P "flatpak install succeeded! \n"
        fi
        clear
        echo -e "\n${YLW}Once inside, type '${RED}python -vvv -m pdb -m amulet_map_editor${YLW}' to run Amulet though ${WHT}PDB${YLW}.\n${NRM}"; sleep 2
        flatpak-builder --run amulet-flatpak_build_dir $AFP_YML sh
        lastWord
    elif DEBUG=FALSE;
        if ! flatpak install -vvv -y -u amulet-x86_64.flatpak; then
            report F "flatpak install failed. \n"
            exit 1
        else
            report P "flatpak install succeeded! \n"
        fi
        echo -e "\n${YLW}Running flatpak...\n${WHT}"
        if ! flatpak run -vvv $AFPBASE; then
            report F "Amulet crashed. Review Traceback logs for details. \n"
            exit 1
        else
            report P "It works! \n"
            lastWord
        fi
    fi
elif AUTO=FALSE; then
    report N report N "${WHT}Auto mode isn't active - you'll have to manually uninstall and reinstall Amulet Flatpak Edition.${NRM}\n"
    lastWord
fi
