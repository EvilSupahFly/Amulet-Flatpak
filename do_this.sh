#!/bin/bash
# Check if the script is running in a Python 3 virtual environment
#if [[ -z "$VIRTUAL_ENV" ]]; then
#    echo -e "Error: This script must be run inside a Python 3 virtual environment."
#    exit 1
#fi

# Function to check if colour output is supported
supports_colour() {
    if [ -t 1 ] && command -v tput &> /dev/null; then
        local colours
        colours=$(tput colors 2>/dev/null)
        if [[ -n "$colours" && "$colours" -ge 8 ]]; then
            return 0  # Colour support detected
        fi
    fi
    return 1  # No colour support
}

# Define high-intensity colours only if supported
if supports_colour; then
    RED=$(tput bold; tput setaf 9)      # Bright Red
    GREEN=$(tput bold; tput setaf 10)    # Bright Green
    YELLOW=$(tput bold; tput setaf 11)   # Bright Yellow
    BLUE=$(tput bold; tput setaf 12)     # Bright Blue
    CYAN=$(tput bold; tput setaf 14)     # Bright Cyan
    WHITE=$(tput bold; tput setaf 15)    # Bright White
    RESET=$(tput sgr0)  # Reset colours
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; WHITE=""; RESET=""
fi

# Function to report after process completions
report() {
    local status=$1 # F = failure, P = pass, N = notice (neutral)
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [[ "$status" == "F" ]]; then
        echo -e "\n${RED}[$timestamp] ERROR: ${WHITE}$message${RESET}"
    elif [[ "$status" == "P" ]]; then
        echo -e "\n${GREEN}[$timestamp] SUCCESS: ${WHITE}$message${RESET}"
    elif [[ "$status" == "N" ]]; then
        echo -e "\n${YELLOW}[$timestamp] NOTICE: ${WHITE}$message${RESET}"
    fi
}

## Variable definitions
DEBUG=FALSE
SETVER=FALSE
DONE_PIP=FALSE
PIP_GEN=FALSE
AUTO=FALSE
#DO_PDB=FALSE
AFPBASE="io.github.evilsupahfly.amulet_flatpak"
AFPREPO="${AFPBASE}-repo"
AFP_YML="${AFPBASE}.yaml"
AFP_XML="${AFPBASE}.metainfo.xml"
AFP_DBG="${AFPBASE}.Debug"
BLD_DIR="amulet_flatpak.build_dir"
I_AM="$0 $@"

bye() {
    if [ "$1" -ne "0" ]; then
        report F "${RED}$I_AM - termination on error at line $1."; echo -e "${RESET}"
        exit 1
    else
        echo -e "${RESET}"
        exit 0
    fi
}

doHelp() {
    report N "${WHITE}This helper script will build and run a version of the amulet-flatpak, among other things.\n"
    echo -e "${WHITE}Upon completion, it assembles '${YELLOW}amulet-x86_64.flatpak${WHITE}' from the local repo."
    echo -e "Options are as follows:"
    echo -e "\n${YELLOW}$0 --just-build"
    echo -e "${WHITE}Running ${YELLOW}--just-build${WHITE} exits after building the flatpak and repo and ${RED}can not ${WHITE}be used in conjunction with any other option except ${YELLOW}--version${WHITE}."
    echo -e "\n${YELLOW}$0 --pip-gen"
    echo -e "Specifying ${WHITE}--pip-gen${WHITE} will run ${GREEN}flatpak-pip-generator${WHITE} to generate a new 'pip-gen.yaml'. However, if ${RED}$AFP_YML${WHITE} or ${RED}pip-gen.yaml${WHITE} don't exist, this ${RED}WILL${WHITE} break things. This option is compatible with all other options except ${YELLOW}--just-build ${WHITE}and ${YELLOW}--help${WHITE}."
    echo -e "\n${YELLOW}$0 --version x.y.z.aa"
    echo -e "${YELLOW}$0 --version=x.y.z.aa"
    echo -e "${WHITE}Running ${WHITE}--version ${WHITE} will override the version number otherwise set by ${YELLOW}$AFP_YML${WHITE}. Version numbers follow the same rules as Python for dotted decimals (i.e. 0.10.36 or 9.10.0.19), and this option is compatible with all other options except ${YELLOW}--just-build ${WHITE}and ${YELLOW}--help${WHITE}."
    echo -e "\n${YELLOW}$0 --auto"
    echo -e "${WHITE}You can also specify ${YELLOW}--auto${WHITE} and this script will also (try) to automatically install and run ${YELLOW}amulet-x86_64.flatpak${WHITE} for you. Limited error checking is included for each step so ${RED}if one step fails${WHITE},we'll try to exit gracefully. ${YELLOW}--auto${WHITE} works with all options except ${YELLOW}--just-build ${WHITE}and ${YELLOW}--help${WHITE}."
    echo -e "\n${YELLOW}$0 --debug"
    echo -e "${WHITE}I've also included a ${YELLOW}--debug${WHITE} option to allow troubleshooting of the Amulet Flatpak inside the flatpak sandbox, if neccessary. ${YELLOW}--debug${WHITE} compatible with all other options except ${YELLOW}--just-build ${WHITE}and ${YELLOW}--help${WHITE}."
#    echo -e "\n${YELLOW}$0 --pdb"
#    echo -e "${WHITE}Complimentary to the ${YELLOW}--debug${WHITE} option, ${YELLOW}--pdb${WHITE} allows troubleshooting of the Amulet Flatpak inside the flatpak sandbox using Python's built-in PDB. ${YELLOW}--pdb${WHITE} only works if ${YELLOW}--debug${WHITE} is also specified."
    echo -e "\n${YELLOW}$0"
    echo -e "${YELLOW}$0 --help"
    echo -e "${WHITE}Running with no options or with ${YELLOW}--help${WHITE} displays this help text. When specifying ${YELLOW}--help${WHITE}, all other options are ignored.${RESET}\n"
    lastWord
}

# Some parting words for future runs
lastWord(){
    report N "\n${WHITE}--------------------------------------------------\n${WHITE}| The last word and some help for terminal users |\n${WHITE}--------------------------------------------------\n"
    echo -e "${WHITE}To install or reinstall the Amulet Flatpak manually, type:"
    echo -e "${YELLOW}    flatpak install -u amulet-x86_64.flatpak"
    echo -e "\n${WHITE}To run your installed flatpak manually, type:"
    echo -e "${YELLOW}    flatpak run $AFPBASE"
    echo -e "\n${WHITE}To run the Amulet Flatpak manually in normal debug mode, type:"
    echo -e "${YELLOW}    flatpak run $AFPBASE $AFP_YML sh"
    echo -e "\n${WHITE}Or, to run the Amulet Flatpak manually in extreme debug mode, type:"
    echo -e "${YELLOW}    flatpak run --ostree-verbose -vv --command=sh --devel --filesystem=$(pwd) $AFPBASE"
    echo -e "\n${WHITE}Once inside the flatpak shell, type:"
    echo -e "${YELLOW}    python -vvv -m pdb -m amulet_map_editor"
    echo -e "\n${WHITE}To uninstall the Amulet flatpak, type:"
    echo -e "${RED}    flatpak uninstall $AFPBASE \n"
    bye 0
}

function doInstall {
    report F "${RED}$1 not found.\n${WHITE}Checking distribution..."
    # Determine the distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        report P "\n${WHITE}Distro determined as ${YELLOW}$DISTRO${WHITE}..." #; sleep 2
        report N "\n${WHITE}Attempting to install $1 for ${YELLOW}$DISTRO${WHITE}..." #; sleep 2
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
                report F "${RED}Unsupported distribution: $DISTRO. \n${WHITE}No known package manager found. Please manually install $1 using your graphical package manager, or contact the author to have $DISTRO support added."
                bye $LINENO
            fi
            ;;
    esac
}

function doFlatpakPIP {
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
#version: $version
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
  - --filesystem=host
  - --filesystem=host-os
  - --filesystem=home
  - --filesystem=home/.cache/AmuletMapEditor:rw
  - --filesystem=home/.config/state/AmuletMapEditor:rw
  - --filesystem=home/.local/share/AmuletMapEditor:rw
  - --filesystem=home/.local/state/AmuletMapEditor:rw
  - --filesystem=home/.local/sate/AmuletMapTeam:rw
  - --persist=home/.cache/AmuletMapEditor
  - --persist=home/.config/state/AmuletMapEditor
  - --persist=home/.local/share/AmuletMapEditor
  - --persist=home/.local/state/AmuletMapEditor
  - --persist=home/.local/sate/AmuletMapTeam
  - --env=LIBGL_ALWAYS_SOFTWARE="0"
  - --env=OPENGL_VERSION=3.3
  - --env=OPENGL_LIB=/usr/lib/x86_64-linux-gnu/libGL.so
  - --env=PS1=[ AMULET_FLATPAK > \w ]\n>
# Uncomment the following options to increase debug output verbosity in the terminal
#  - --env=PYTHONDEBUG=3
#  - --env=PYTHONVERBOSE=3
#  - --env=PYTHONTRACEMALLOC=10
#  - --env=G_MESSAGES_DEBUG=all

modules:
  - shared-modules/glew/glew.json
  - shared-modules/glu/glu-9.json
  - pip-gen.yaml
  - name: metainfo-xml
    buildsystem: simple
    build-commands:
      - install -Dm644 io.github.evilsupahfly.amulet_flatpak.metainfo.xml -t ${FLATPAK_DEST}/share/metainfo/
    sources:
      - type: file
        path: io.github.evilsupahfly.amulet_flatpak.metainfo.xml
  - name: metainfo-desktop
    buildsystem: simple
    build-commands:
      - install -Dm755 io.github.evilsupahfly.amulet_flatpak.desktop -t ${FLATPAK_DEST}/share/applications/
    sources:
      - type: file
        path: io.github.evilsupahfly.amulet_flatpak.desktop
  - name: metainfo-ico
    buildsystem: simple
    build-commands:
      - install -Dm644 io.github.evilsupahfly.amulet_flatpak.png -t ${FLATPAK_DEST}/share/icons/hicolor/256x256/apps/
    sources:
      - type: file
        path: io.github.evilsupahfly.amulet_flatpak.png
#### <<< Generated by do_this.sh
EOL
report P "flatpak-pip-generator succeeded!"
DONE_PIP=TRUE
}

check_version() {
    local version="$1"
    report N "${WHITE}Checking for version number..." #; sleep 2
    if [[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        report P "Using version ${GREEN}$version${WHITE}."
        AFP_VER=$version
    else
        report F "'${RED}$version${WHITE}' must be a dotted decimal number."
        bye $LINENO
    fi
}

clear
report N "\n${WHITE}--------------------------------\n| PRELIMINARY CHECKS INITIATED |\n--------------------------------"
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
            report N "${WHITE}DEBUG=TRUE"
            shift
            ;;
        #--pdb)
        #    DO_PDB=TRUE
        #    report N "${WHITE}DEBUG=TRUE"
        #    shift
        #    ;;
        --auto)
            AUTO=TRUE
            report N "${WHITE}AUTO=TRUE"
            shift
            ;;
        --pip-gen)
            PIP_GEN=TRUE
            report N "${WHITE}PIP_GEN=TRUE"
            shift
            ;;
        *)
            report F "Invalid option: $1"
            bye $LINENO
            ;;
    esac
done

# If "--version" was not provided, then read from $AFP_YML
if [[ -z "$AFP_VER" ]]; then
    check_version "$(grep -oP '#version: \K[0-9]+(\.[0-9]+)*' "$AFP_YML")"
fi

# Check if Flatpak is installed at the user level
report N "${WHITE}Checking for Flatpak..."
if ! command -v flatpak &> /dev/null; then
    # sleep 2
    doInstall flatpak
    # Verify if the installation was successful
    if ! command -v flatpak &> /dev/null; then
        report F "${RED}Installation of Flatpak failed. ${YELLOW}Please check your package manager logs for more details."
        bye $LINENO
    fi
    report N "${WHITE}Adding 'flathub' repository..." #; sleep 2
    if ! flatpak -v remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        report F "${RED}Flathub repository couldn't be added."
        bye $LINENO
    else
        report P "${GREEN}Flathub repository added successfully."
    fi
else
    report P "${WHITE}Install verified. Checking for updates...\n" #; sleep 2
    flatpak update -y -u
fi

# Check if Flatpak Builder is installed at the user level
report N "${WHITE}Checking for Flatpak Builder... " #; sleep 2
if ! command -v flatpak-builder &> /dev/null; then
    # sleep 2
    doInstall flatpak-builder
    # Verify if the installation was successful
    if ! command -v flatpak-builder &> /dev/null; then
        report F "${RED}Installation of flatpak-builder failed. ${YELLOW}Please check your package manager logs for more details."
        bye $LINENO
    fi
fi

if ! flatpak list | grep -q "org.flatpak.Builder"; then
    # sleep 2
    if ! flatpak -v install --user -y org.flatpak.Builder; then
        report F "${RED}Fatal Error: ${WHITE}org.flatpak.Builder couldn't be installed."
        bye $LINENO
    fi
fi

report P "${WHITE}Install verified." #; sleep 2

# Check for AppStream (appstreamcli), install if it's missing
report N "${WHITE}Checking for AppStream..." #; sleep 2

if ! command -v appstreamcli &> /dev/null; then
    # sleep 2
    doInstall appstream
    # Check if installation was successful
    if ! command -v appstreamcli &> /dev/null; then
        report F "${RED}Installation via package manager failed. \n${WHITE}Try installing manually."
        bye $LINENO
    fi
else
    report P "${WHITE}Install verified." #; sleep 2
fi

report N "\n${WHITE}--------------------------------\n| PRELIMINARY CHECKS COMPLETED |\n--------------------------------"
sleep 2

if [[ "$PIP_GEN" == "FALSE" ]]; then
    report N "${WHITE}Skipping ${YELLOW}flatpak-pip-generator${WHITE}, starting ${YELLOW}flatpak-builder${WHITE}."
    # sleep 2
elif [[ "$PIP_GEN" == "TRUE" ]]; then
    doFlatpakPIP
fi

# Attempt to build Frankenstein's Monster - change "tag" when updating to newer Amulet versions
report N "${WHITE}flatpak-builder -vvv --user --rebuild-on-sdk-change --install-deps-from=flathub --add-tag=v$AFP_VER --bundle-sources --repo=$AFPREPO $BLD_DIR $AFP_YML --force-clean\n${GREEN}"
if ! flatpak-builder -vvv --user --rebuild-on-sdk-change --install-deps-from=flathub --add-tag=$AFP_VER --bundle-sources --repo=$AFPREPO $BLD_DIR $AFP_YML --force-clean; then
    report F "flatpak-builder failed."
    bye $LINENO
fi

report P "flatpak-builder succeeded!"

# Bundle the contents of the local repository into "amulet-x86_64.flatpak"
report N "${WHITE}flatpak --gpg-homedir=$HOME/.gnupg build-bundle -vvv $AFPREPO amulet-x86_64.flatpak $AFPBASE"
if ! flatpak --gpg-homedir=$HOME/.gnupg build-bundle -vvv $AFPREPO amulet-x86_64.flatpak $AFPBASE; then
    report F "flatpak build-bundle failed."
    bye $LINENO
fi

report P "flatpak build-bundle succeeded!"
# Install bundle
report N "${YELLOW}Installing bundle..."

if [ ! -f "amulet-x86_64.flatpak" ]; then
    report F "${RED}FATAL ERROR: ${WHITE}Installation file '${YELLOW}amulet-x86_64.flatpak${WHITE}' has disappeared. Terminating script."
    bye $LINENO
fi

if [ "$AUTO" = "TRUE" ]; then
    report N "\n${WHITE}---------------------\n| AUTO MODE ACTIVE. |\n---------------------\n\n${WHITE}Checking for a previous version..."
    if flatpak list | grep -q "$AFPBASE"; then
        report N "${WHITE}Previous version found. Removing..."
        flatpak --user uninstall -y "$AFPBASE"
        report N "${WHITE}Installing new version."
    else
        report N "${RED}Previous version not found. ${WHITE}Installing new version."
    fi
else
    report N "${RED}Auto mode isn't active. ${WHITE}You'll have to manually uninstall and reinstall Amulet Flatpak Edition."
    lastWord
fi

if [ "$DEBUG" = "TRUE" ]; then
    report N "${WHITE}Running DEBUG install...\nflatpak install --include-sdk --include-debug -vvv -y --user amulet-x86_64.flatpak\n"
    if ! flatpak install --include-sdk --include-debug -vvv -y --user amulet-x86_64.flatpak; then
        report F "Amulet Flatpak install failed."
        bye $LINENO
    else
        report P "Amulet Flatpak install succeeded."
        report N "${WHITE}Configuring Debug extension ($AFP_DBG)" #; sleep 2
        if ! flatpak install --user -y ./$AFPREPO $AFP_DBG; then
            report F "$AFP_DBG failed"; echo -e "${WHITE}"
            read -p "Try to continue without $AFP_DBG (y/n)? " tryCont
            case $tryCont in
                n) bye $LINENO
                ;;
            esac
        fi
    fi
    #clear
    report N "${WHITE}Auto-Mode active. DEBUG mode active." #; sleep 2
    echo -e "\n${WHITE}To run amulet, you can do one of two things once you're in the flatpak shell:"
    echo -e "1: Run amulet with the built-in Python Debugger like so: python -m pdb -m amulet_map_editor"
    echo -e "2. Run amulet as-is like so: python -m amulet_map_editor"
    echo -e "Amulet also has a ${YELLOW}--debug${WHITE} switch you can pass for greater output in either of the above cases."
    if ! flatpak run --ostree-verbose -vv --command=sh --devel --filesystem=$(pwd) $AFPBASE; then
        report F "Amulet Flatpak install failed."
        bye $LINENO
    fi
else
    report N "${WHITE}Auto-Mode active. Starting flatpak install." #; sleep 2
    echo -e "${WHITE}flatpak install -y --user amulet-x86_64.flatpak\n"
    if ! flatpak-builder --run $BLD_DIR $AFP_YML sh; then
        report F "${RED}flatpak install failed."
        bye $LINENO
    else
        report P "flatpak install succeeded."
    fi
    report N "${WHITE}Auto-Mode active. Running flatpak." #; sleep 2
    if ! flatpak run --ostree-verbose $AFPBASE; then
        report F "${RED}Amulet launch failed. Please review terminal output."
        bye $LINENO
    fi
fi

report P "Looks like it probably worked. If it didn't, then something is really messed up."
lastWord
