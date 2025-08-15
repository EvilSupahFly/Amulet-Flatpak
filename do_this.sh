#!/bin/bash

## Colour Definitions
GRN="\033[1m\033[1;92m" # Green
NRM="\033[0m" # Normal
PRP="\033[1m\033[35m" # Magenta (Purple)
RED="\033[1m\033[1;91m" # Red
WHT="\033[1m\033[1;97m" # White
YLW="\033[1m\033[1;33m" # Yellow

## Variable definitions
AFPBASE="io.github.evilsupahfly.amulet_flatpak"
AFP_DBG="${AFPBASE}.Debug"
AFPREPO="${AFPBASE}-repo"
AFP_VER=""
AFP_XML="${AFPBASE}.metainfo.xml"
AFP_YML="${AFPBASE}.yaml"
APP_DIR="/home/$(whoami)/.var/app/io.github.evilsupahfly.amulet_flatpak"
AUTO=FALSE
BLD_DIR="amulet_flatpak.build_dir"
CLEAN=FALSE
CUSTOM=FALSE
DEBUG=FALSE
DO_AFP=FALSE
DO_CMD=FALSE
DONE_PIP=FALSE
I_AM="$0 $@"
LAUNCHER="amulet_map_editor"
PIP_GEN=FALSE
SETVER=FALSE

bye() {
    if [ "$1" -ne "0" ]; then
        report F "${RED}$I_AM - termination on error at line $1."; echo -e "${NRM}"
        exit 1
    else
        echo -e "${NRM}"
        exit 0
    fi
}

doHelp() {
    report N "${WHT}This helper script will build and run a version of the amulet-flatpak, among other things.\n"
    echo -e "${WHT}Upon completion, it assembles '${YLW}amulet-x86_64.flatpak${WHT}' from the local repo."
    echo -e "Options are as follows:"
    echo -e "\n${YLW}$0 --just-build"
    echo -e "${WHT}Running ${YLW}--just-build${WHT} exits after building the flatpak and repo and ${RED}can not ${WHT}be used in conjunction with any other option except ${YLW}--version${WHT}."
    echo -e "\n${YLW}$0 --pip-gen"
    echo -e "Specifying ${WHT}--pip-gen${WHT} will run ${GRN}flatpak-pip-generator${WHT} to generate a new 'pip-gen.yaml'. However, if ${RED}$DEFAULT_YML${WHT} or ${RED}pip-gen.yaml${WHT} don't exist, this ${RED}WILL${WHT} break things. This option is compatible with all other options except ${YLW}--just-build ${WHT}and ${YLW}--help${WHT}."
    echo -e "\n${YLW}$0 --version x.y.z.aa"
    echo -e "${YLW}$0 --version=x.y.z.aa"
    echo -e "${WHT}Running ${WHT}--version ${WHT} will override the version number otherwise set by ${YLW}$AFP_YML${WHT}. Version numbers follow the same rules as Python for dotted decimals (i.e. 0.10.36 or 9.10.0.19), and this option is compatible with all other options except ${YLW}--just-build ${WHT}and ${YLW}--help${WHT}."
    echo -e "\n${YLW}$0 --auto"
    echo -e "${WHT}You can also specify ${YLW}--auto${WHT} and this script will also (try) to automatically install and run ${YLW}amulet-x86_64.flatpak${WHT} for you. Limited error checking is included for each step so ${RED}if one step fails${WHT},we'll try to exit gracefully. ${YLW}--auto${WHT} works with all options except ${YLW}--just-build ${WHT}and ${YLW}--help${WHT}."
    echo -e "\n${YLW}$0 --debug"
    echo -e "${WHT}I've also included a ${YLW}--debug${WHT} option to allow troubleshooting of the Amulet Flatpak inside the flatpak sandbox, if neccessary. ${YLW}--debug${WHT} compatible with all other options except ${YLW}--just-build ${WHT}and ${YLW}--help${WHT}."
    #echo -e "\n${YLW}$0 --yaml \"full/path/to/file.yaml\""
    #echo -e "${WHT}Works with all other options. If you don't specify your own YAML manifest, this script will default to ${YLW}$DEFAULT_YML${WHT}. Optional."
    echo -e "\n${YLW}$0"
    echo -e "${YLW}$0 --help"
    echo -e "${WHT}Running with no options or with ${YLW}--help${WHT} displays this help text. When specifying ${YLW}--help${WHT}, all other options are ignored.${NRM}\n"
    lastWord
}

# Some parting words for future runs
lastWord(){
    report N "\n${WHT}--------------------------------------------------\n${WHT}| The last word and some help for terminal users |\n${WHT}--------------------------------------------------"
    echo -e "${WHT}To install or reinstall the Amulet Flatpak manually, type:"
    echo -e "${YLW}    flatpak install -u amulet-x86_64.flatpak"
    echo -e "\n${WHT}To run your installed flatpak manually, type:"
    echo -e "${YLW}    flatpak run $AFPBASE"
    echo -e "\n${WHT}To run the Amulet Flatpak manually in normal debug mode, type:"
    echo -e "${YLW}    flatpak run $AFPBASE $AFP_YML sh"
    echo -e "\n${WHT}Or, to run the Amulet Flatpak manually in extreme debug mode, type:"
    echo -e "${YLW}    flatpak run --command=sh --devel --filesystem=$(pwd) $AFPBASE"
    echo -e "\n${WHT}Once inside the flatpak shell, type:"
    echo -e "${YLW}    python -vvv -m pdb -m amulet_map_editor"
    echo -e "\n${WHT}To uninstall the Amulet flatpak, type:"
    echo -e "${RED}    flatpak uninstall $AFPBASE \n"
    bye 0
}

# Function to report after process completions
report() {
    local status=$1 # F = failure, P = pass, N = notice (neutral)
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [[ "$status" == "F" ]]; then
        echo -e "\n${RED}[$timestamp] ERROR: ${WHT}$message${NRM}"
    elif [[ "$status" == "P" ]]; then
        echo -e "\n${GRN}[$timestamp] SUCCESS: ${WHT}$message${NRM}"
    elif [[ "$status" == "N" ]]; then
        echo -e "\n${YLW}[$timestamp] NOTICE: ${WHT}$message${NRM}"
    fi
}

function doInstall {
    report F "${RED}$1 not found.\n${WHT}Checking distribution..."
    # Determine the distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        report P "\n${WHT}Distro determined as ${YLW}$DISTRO${WHT}..." #; sleep 2
        report N "\n${WHT}Attempting to install $1 for ${YLW}$DISTRO${WHT}..." #; sleep 2
    fi

    # Determine the package manager and install the package
    case $DISTRO in
        ubuntu|debian)
            sudo apt update && sudo apt install -y $1
            ;;
        fedora)
            sudo dnf install -y $1
            ;;
        centos|rhel)
            sudo yum install -y $1
            ;;
        arch|endeavouros)
            sudo pacman -Syu $1
            ;;
        opensuse)
            sudo zypper install -y $1
            ;;
        *)
            # Fallback to package manager detection if distro detection fails
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y $1
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y $1
            elif command -v yum &> /dev/null; then
                sudo yum install -y $1
            elif command -v pacman &> /dev/null; then
                sudo pacman -Syu $1
            elif command -v zypper &> /dev/null; then
                sudo zypper install -y $1
            else
                report F "${RED}Unsupported distribution: $DISTRO. \n${WHT}No known package manager found. Please manually install $1 using your graphical package manager, or contact the author to have $DISTRO support added."
                bye $LINENO
            fi
            ;;
    esac
}

function doFlatpakPIP {
    # Check if the script is running in a Python 3 virtual environment
    if [[ -z "$VIRTUAL_ENV" ]]; then
        report F "${RED}Error: ${WHITE}This script must be run inside a Python 3 virtual environment."
        bye $LINENO
    fi
    if ! pip install -U pip pyyaml requirements-parser; then
        report F "${RED}Error: ${WHITE}Failed to install required PIP packages."
        bye $LINENO
    fi

    # Generate everything we need to build Amulet in the Flatpak sandbox
    if ! ./flatpak-pip-generator --requirements-file=requirements.txt --yaml --output=pip-gen; then
        report F "flatpak-pip-generator failed."
        bye $LINENO
    fi

    # Create the initial header for our primary manifest
cat << EOL > "$AFP_YML"
#### Generated by do_this.sh >>>
id: $AFPBASE
#name: Amulet Map Editor
#version: $AFP_VER
runtime: org.freedesktop.Platform
runtime-version: '24.08'
sdk: org.freedesktop.Sdk
command: amulet_map_editor

finish-args:
  - --device=all
  - --device=dri
  - --allow=devel
  - --allow=per-app-dev-shm
  - --share=network
  - --share=ipc
  - --socket=wayland
  - --socket=fallback-x11
  - --unset-env=XDG_STATE_HOME
  - --unset-env=XDG_CONFIG_HOME
  - --unset-env=XDG_DATA_HOME
  - --unset-env=XDG_CACHE_HOME
  - --filesystem=host
  - --filesystem=host-os
  - --filesystem=home:create
  - --filesystem=~/.cache/AmuletMapEditor:create
  - --filesystem=~/.local/state/AmuletMapEditor:create
  - --filesystem=~/.local/state/AmuletMapTeam:create
  - --filesystem=~/.local/share/AmuletMapEditor:create
  - --filesystem=~/.config/state/AmuletMapEditor:create
  - --env=LIBGL_ALWAYS_SOFTWARE="0"
  - --env=OPENGL_VERSION=3.3
  - --env=OPENGL_LIB=/usr/lib/x86_64-linux-gnu/libGL.so
  - --env=PS1=[ AMULET_FLATPAK > \w]\n>
# Uncomment the following options to increase debug output verbosity in the terminal
#  - --env=PYTHONDEBUG=3
#  - --env=PYTHONVERBOSE=3
#  - --env=PYTHONTRACEMALLOC=10
#  - --env=G_MESSAGES_DEBUG=all

modules:
  - shared-modules/glew/glew.json
  - shared-modules/glu/glu-9.json
  - updates.yaml
  - psutil.yaml
  - pip-gen.yaml
    buildsystem: simple
    build-commands:
      - install -Dm644 $AFP_XML -t \${FLATPAK_DEST}/share/metainfo/
    sources:
      - type: file
        path: $AFP_XML
  - name: metainfo-desktop
    buildsystem: simple
    build-commands:
      - install -Dm755 $AFPBASE.desktop -t \${FLATPAK_DEST}/share/applications/
    sources:
      - type: file
        path: $AFPBASE.desktop
  - name: metainfo-ico
    buildsystem: simple
    build-commands:
      - install -Dm644 $AFPBASE.png -t \${FLATPAK_DEST}/share/icons/hicolor/256x256/apps/
    sources:
      - type: file
        path: $AFPBASE.png
#### <<< Generated by do_this.sh
EOL
report P "flatpak-pip-generator succeeded!"
DONE_PIP=TRUE
}

check_version() {
    local version="$1"
    report N "${WHT}Checking for version number..." #; sleep 2
    if [[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        report P "Using version ${GRN}$version${WHT}."
        AFP_VER=$version
    else
        report F "'${RED}$version${WHT}' must be a dotted decimal number."
        bye $LINENO
    fi
}

clear
report N "\n${WHT}--------------------------------\n| PRELIMINARY CHECKS INITIATED |\n--------------------------------"
sleep 2

PCOUNT=$#
if [ $PCOUNT -eq 0 ]; then
    doHelp
fi

while [[ "$1" != "" ]]; do
    case $1 in
        --version)
            shift
            check_version "$1"
            shift
            ;;
        --version=*)
            check_version "${1#*=}"
            shift
            ;;
        --help)
            doHelp
            ;;
        --debug)
            DEBUG=TRUE
            report N "${WHT}DEBUG=TRUE"
            shift
            ;;
        --auto)
            AUTO=TRUE
            report N "${WHT}AUTO=TRUE"
            shift
            ;;
        --pip-gen)
            PIP_GEN=TRUE
            report N "${WHT}PIP_GEN=TRUE"
            shift
            ;;
        --cmd)
            if [ -z "$CMD_OR_AFP_CHOSEN" ]; then
                DO_CMD=TRUE
                CMD_OR_AFP_CHOSEN="cmd"
                report N "${WHT}DO_CMD=TRUE"
                LAUNCHER="sh"
            elif [ "$CMD_OR_AFP_CHOSEN" = "afp" ]; then
                report F "${YLW}Ignoring ${RED}--cmd${YLW}: --afp was already specified. Please only choose one next time."
            fi
            shift
            ;;
        --afp)
            if [ -z "$CMD_OR_AFP_CHOSEN" ]; then
                DO_AFP=TRUE
                CMD_OR_AFP_CHOSEN="afp"
                report N "${WHT}DO_AFP=TRUE"
            elif [ "$CMD_OR_AFP_CHOSEN" = "cmd" ]; then
                report F "${YLW}Ignoring ${RED}--afp${YLW}: --cmd was already specified. Please only choose one next time."
            fi
            shift
            ;;
        *)
            report F "Invalid option: $1"
            bye $LINENO
            ;;
    esac
done

# Set default or custom YAML based on arguments passed at launch
#if [[ $CUSTOM == "TRUE" ]]; then
#    AFP_YML="$NEWYAML"
#elif [[ $CUSTOM == "FALSE" ]]; then
#    report N "${WHT}CUSTOM=FALSE"
#    AFP_YML="$DEFAULT_YML"
#fi
#report N "${WHT}AFP_YAML=$AFP_YML"



# If "--version" was not provided, then read from $AFP_YML
if [[ -z "$AFP_VER" ]]; then
    check_version "$(grep -oP '#version: \K[0-9]+(\.[0-9]+)*' "$AFP_YML")"
fi

# Check if Flatpak is installed at the user level
report N "${WHT}Checking for Flatpak..."
if ! command -v flatpak &> /dev/null; then
    # sleep 2
    doInstall flatpak
    # Verify if the installation was successful
    if ! command -v flatpak &> /dev/null; then
        report F "${RED}Installation of Flatpak failed with error $?. ${YLW}Please check your package manager logs for more details."
        bye $LINENO
    fi
    report N "${WHT}Adding 'flathub' repository..." #; sleep 2
    if ! flatpak -v remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        report F "${RED}Flathub repository couldn't be added."
        bye $LINENO
    else
        report P "${GRN}Flathub repository added successfully."
    fi
else
    report P "${WHT}Install verified. Checking for updates..." #; sleep 2
    flatpak update -y -u
fi

# Check if Flatpak Builder is installed at the user level
report N "${WHT}Checking for Flatpak Builder... " #; sleep 2
if ! command -v flatpak-builder &> /dev/null; then
    # sleep 2
    doInstall flatpak-builder
    # Verify if the installation was successful
    if ! command -v flatpak-builder &> /dev/null; then
        report F "${RED}Installation of flatpak-builder failed with error $?. ${YLW}Please check your package manager logs for more details."
        bye $LINENO
    fi
fi

if ! flatpak list | grep -q "org.flatpak.Builder"; then
    # sleep 2
    if ! flatpak -v install --user -y org.flatpak.Builder; then
        report F "${RED}Fatal Error $?. ${WHT}org.flatpak.Builder couldn't be installed."
        bye $LINENO
    fi
fi

report P "${WHT}Install verified." #; sleep 2

# Check for AppStream (appstreamcli), install if it's missing
report N "${WHT}Checking for AppStream..." #; sleep 2

if ! command -v appstreamcli &> /dev/null; then
    # sleep 2
    doInstall appstream
    # Check if installation was successful
    if ! command -v appstreamcli &> /dev/null; then
        report F "${RED}Installation via package manager failed with error ${RED}$?${WHT}. \n${WHT}Try installing manually."
        bye $LINENO
    fi
else
    report P "${WHT}Install verified." #; sleep 2
fi

report N "\n${WHT}--------------------------------\n| PRELIMINARY CHECKS COMPLETED |\n--------------------------------"
sleep 2

report N "${WHT}Checking for previous builds..." #; sleep 2

# Array of directories to check and remove
directories=("$BLD_DIR" ".flatpak-builder" "$AFPREPO")

# Loop through each directory and remove if it exists
for dir in "${directories[@]}"; do
    if [[ "$CLEAN" == "FALSE" ]]; then
        CLEAN=TRUE
    fi
    if [ -d "$dir" ]; then
        report N "${WHT}Found '${YLW}$dir${WHT}' - removing now..." ; sleep 1
        rm -rf "$dir"
        report N "${WHT}'$dir' has been removed."
    fi
done

if [ -f "amulet-x86_64.flatpak" ]; then
    CLEAN=TRUE
    report N "${WHT}Found '${YLW}amulet-x86_64.flatpak${WHT}' - removing now..." ; sleep 1
    rm -f "amulet-x86_64.flatpak"
    report N "${WHT}'amulet-x86_64.flatpak' has been removed."
fi

if [[ "$CLEAN" == "FALSE" ]]; then
    report N "${WHT}Skipping clean-up - no previous builds found."
elif [[ "$CLEAN" == "TRUE" ]]; then
    report N "${WHT}Clean-up completed."
fi

if [[ "$PIP_GEN" == "FALSE" ]]; then
    report N "${WHT}Manifest already exists: skipping ${YLW}flatpak-pip-generator${WHT}, launching ${YLW}flatpak-builder${WHT}."
    # sleep 2
elif [[ "$PIP_GEN" == "TRUE" ]]; then
    doFlatpakPIP
fi

# Attempt to build Frankenstein's Monster - change "tag" when updating to newer Amulet versions
report N "${WHT}flatpak-builder -vvv --user --rebuild-on-sdk-change --install-deps-from=flathub --add-tag=v$AFP_VER --bundle-sources --repo=$AFPREPO $BLD_DIR $AFP_YML --force-clean 2>&1 | tee build.log\n${GRN}"
if ! flatpak-builder -vvv --user --rebuild-on-sdk-change --install-deps-from=flathub --add-tag=v$AFP_VER --bundle-sources --repo=$AFPREPO $BLD_DIR $AFP_YML --force-clean 2>&1 | tee build.log; then
    report F "flatpak-builder failed with error ${RED}$?${WHT}."
    bye $LINENO
fi

report P "flatpak-builder succeeded!"

# Bundle the contents of the local repository into "amulet-x86_64.flatpak"
report N "${WHT}flatpak --gpg-homedir=$HOME/.gnupg build-bundle -vvv $AFPREPO amulet-x86_64.flatpak $AFPBASE"
if ! flatpak --gpg-homedir=$HOME/.gnupg build-bundle -vvv $AFPREPO amulet-x86_64.flatpak $AFPBASE; then
    report F "flatpak build-bundle failed."
    bye $LINENO
fi
if [[ "$DEBUG" == "TRUE" ]]; then
    report N "${WHT}flatpak --gpg-homedir=$HOME/.gnupg build-bundle -vvv $AFPREPO amulet-x86_64.flatpak $AFP_DBG\n${GRN}"
    if ! flatpak --gpg-homedir=$HOME/.gnupg build-bundle -vvv $AFPREPO amulet-x86_64.flatpak $AFP_DBG; then
        report F "debug build-bundle build failed."
    fi
fi
report P "standard build-bundle succeeded"
# Install bundle
report N "${YLW}Installing bundle..."

if [ ! -f "amulet-x86_64.flatpak" ]; then
    report F "${RED}FATAL ERROR: ${WHT}Installation file '${YLW}amulet-x86_64.flatpak${WHT}' has disappeared. Terminating script."
    bye $LINENO
fi

if [ "$AUTO" = "TRUE" ]; then
    report N "\n${WHT}---------------------\n| AUTO MODE ACTIVE. |\n---------------------\n\n${WHT}Checking for a previous version..."
    if flatpak list | grep -q "$AFPBASE"; then
        report N "${WHT}Previous version found. Removing..."
        flatpak --user uninstall -y "$AFPBASE"
        rm -rf "$APP_DIR"
        report N "${WHT}Installing new version."
    else
        report N "${RED}Previous version not found. ${WHT}Installing new version."
    fi
else
    report N "${RED}Auto mode isn't active. ${WHT}You'll have to manually uninstall and reinstall Amulet Flatpak Edition."
    lastWord
fi

if [ "$DEBUG" = "TRUE" ]; then
    report N "${WHT}Running DEBUG install...\nflatpak install --include-sdk --include-debug -vvv -y --user amulet-x86_64.flatpak\n"
    if ! flatpak install --include-sdk --include-debug -vvv -y --user amulet-x86_64.flatpak; then
        report F "Amulet Flatpak install failed."
        bye $LINENO
    else
        report P "Amulet Flatpak install succeeded."
        report N "${WHT}Configuring Debug extension ($AFP_DBG)"; sleep 2
        if ! flatpak install --user -y ./$AFPREPO $AFP_DBG; then
            report F "$AFP_DBG failed"; echo -e "${WHT}"
            read -p "Try to continue without $AFP_DBG (y/n)? " tryCont
            case $tryCont in
                n) bye $LINENO
                ;;
            esac
        fi
    fi
    clear
    report N "${WHT}Auto-Mode active. DEBUG mode active." #; sleep 2
    echo -e "\n${WHT}To run amulet, you can do one of two things once you're in the flatpak shell:"
    echo -e "1: Run amulet with the built-in Python Debugger like so: python -m pdb -m amulet_map_editor"
    echo -e "2. Run amulet as-is like so: python -m amulet_map_editor"
    echo -e "Amulet also has a ${YLW}--debug${WHT} switch you can pass for greater output in either of the above cases.\n"
    echo -e "${GRN}flatpak run --command=${LAUNCHER} --devel --filesystem=$(pwd) $AFPBASE\n${NRM}"
    if ! flatpak run --command=${LAUNCHER} --devel --filesystem=$(pwd) $AFPBASE; then
        report F "Amulet Flatpak launch failed with error ${RED}$?${WHT}."
        bye $LINENO
    fi
else
    report N "${WHT}Auto-Mode active. Starting flatpak install.\n" #; sleep 2
    echo -e "${WHT}flatpak install -y --user amulet-x86_64.flatpak\n"
    if ! flatpak install -vvv -y --user amulet-x86_64.flatpak; then
        report F "${RED}flatpak install failed with error ${RED}$?${WHT}."
        bye $LINENO
    else
        report P "flatpak install succeeded."
    fi
    clear
    report N "${WHT}Auto-Mode active. Running flatpak." #; sleep 2
    if ! flatpak run --ostree-verbose $AFPBASE; then
        report F "${RED}Amulet launch  failed with error ${RED}$?${WHT}. Please review terminal output."
        bye $LINENO
    fi
fi

report P "Looks like it probably worked. If it didn't, then something is really messed up."
lastWord
