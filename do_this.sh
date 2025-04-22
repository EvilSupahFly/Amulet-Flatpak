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
    WHITE=$(tput bold; tput setaf 15)    # Bright White
    RESET=$(tput sgr0)  # Reset colours
else
    RED=""; GREEN=""; YELLOW=""; WHITE=""; RESET=""
fi

# Display status messages with colours
report() {
    local status=$1  # F = failure, P = pass, N = notice (neutral), B = Blank
    local message=$2  # F = failure, P = pass, N = notice (neutral), B = Blank
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local ERR_MSG="[$timestamp] ERROR: "
    local PASSMSG="[$timestamp] SUCCESS: "
    local NOTEMSG="[$timestamp] NOTICE: "

    # Ensure color variables are defined
    local output_message
    local log_message  # New variable for logging
    if [[ -z "$RED" ]]; then
        output_message="[$timestamp] $message"
        log_message="[$timestamp] $message"  # Plain message for log
    else
        case "$status" in
            F) output_message="${RED}$ERR_MSG ${WHITE}$message${RESET}"
               log_message="$ERR_MSG $message" ;;  # Plain message for log
            P) output_message="${GREEN}$PASSMSG ${WHITE}$message${RESET}"
               log_message="$PASSMSG $message" ;;  # Plain message for log
            N) output_message="${YELLOW}$NOTEMSG ${WHITE}$message${RESET}"
               log_message="$NOTEMSG $message" ;;  # Plain message for log
            B) output_message="${WHITE}$message${RESET}"
               log_message="$message" ;;  # Plain message for log
            *) output_message="${RED}$ERR_MSG ${WHITE}$status is an unsupported status flag.${RESET}"
               log_message="$ERR_MSG $status is an unsupported status flag." ;;  # Plain message for log
        esac
    fi

    # Output to terminal
    echo -e "$output_message"
    # Log to run.log
    #doLog "do_this" "$log_message"  # Log the plain message
}

#doLog() {
#    # Function to handle renaming of log files
#    local base_name="$1"
#    local log_message="$2"
#    local log_file="${base_name}.log"
#    local backup_file="${base_name}.bak"
#    local LOGCHECK=false
#    if [ "$3" == "--check" ]; then
#        AUTO=true
#        LOGCHECK=true
#        echo "Checking log file status..."; sleep 2
#    fi
#    if [ "$WRITING_LOG" == "false" ]; then
#        # Check if the log file already exists
#        if [ -e "$log_file" ]; then
#            # Check if the backup file already exists
#            if [ -e "$backup_file" ]; then
#                if [ "$AUTO" = "false" ]; then
#                    echo "${backup_file} already exists. Do you want to rename it? (y/n) "; read -r response
#                else
#                    response="n"
#                fi
#                if [[ "$response" == "y" ]]; then
#                    echo "Please enter a new name for the backup file: "; read -r new_name
#                    mv -v "$backup_file" "$new_name"
#                    echo "Renamed existing backup file to $new_name"
#                else
#                    rm "$backup_file"
#                    echo "Deleted existing backup file ${backup_file}"
#                fi
#            fi
#            # Rename existing log file to .bak
#            mv -v "$log_file" "$backup_file"
#            echo "Renamed existing log file to ${backup_file}"
#        fi
#        if [ "$LOGCHECK" == "false" ]; then
#            # Write the log message to the new log file
#            echo "$log_message" > "$log_file" || echo "Failed to write to ${log_file}."
#        fi
#        WRITING_LOG=true  # Set to true after the first write
#    else
#        if [ "$LOGCHECK" == "false" ]; then
#            # Write the log message to the existing log file
#            echo "$log_message" >> "$log_file" || echo "Failed to write to ${log_file}."
#        fi
#    fi
#    if [ "$LOGCHECK" == "true" ]; then
#        AUTO=false
#        LOGCHECK=false
#    fi
#}

#doLog "rebuild" "Clean-up log." "--check"

bye() {
    if [ "$1" -ne "0" ]; then
        report F "${RED}$I_AM - termination on error at line $1."; echo -e "${RESET}"
        echo -e "\a"; echo -e "\a"
        exit 1
    else
        echo -e "${RESET}"
        echo -e "\a"
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
        report N "\n${WHITE}Attempting to install \"$1\" for ${YELLOW}$DISTRO${WHITE}..." #; sleep 2
    fi

    # Determine the package manager and install the package
    case $DISTRO in
        ubuntu|debian)
            sudo apt update && sudo apt install -y "$1"
            ;;
        fedora)
            sudo dnf install -y "$1"
            ;;
        centos|rhel)
            sudo yum install -y "$1"
            ;;
        arch|endeavouros)
            sudo pacman -Syu "$1"
            ;;
        opensuse)
            sudo zypper install -y "$1"
            ;;
        *)
            # Fallback to package manager detection if distro detection fails
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y "$1"
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y "$1"
            elif command -v yum &> /dev/null; then
                sudo yum install -y "$1"
            elif command -v pacman &> /dev/null; then
                sudo pacman -Syu "$1"
            elif command -v zypper &> /dev/null; then
                sudo zypper install -y "$1"
            else
                report F "${RED}Unsupported distribution: $DISTRO. \n${WHITE}No known package manager found. Please manually install \"$1\" using your graphical package manager, or contact the author to have $DISTRO support added."
                bye $LINENO
            fi
            ;;
    esac
}

function doFlatpakPIP {
    # Generate everything we need to build Amulet in the Flatpak sandbox
    if ! ./flatpak-pip-generator -r requirements.txt --yaml -o amulet_core; then
        report F "flatpak-pip-generator failed."
        bye $LINENO
    fi
    if [ $DO_YHIS_YAML = "" ]; then
        DO_THIS_YAML="pip-gen.yaml"
    fi
    # Create the initial header for our primary manifest
cat << EOL > "$AFP_YML"
#### Generated by do_this.sh >>>
app-id: $AFPBASE
#name: Amulet Map Editor
#version: $AFP_VER
runtime: org.freedesktop.Platform
runtime-version: '24.08'
sdk: org.freedesktop.Sdk
command: amulet

finish-args:
  - --device=all
  - --device=dri
  - --add-policy=org.freedesktop.Platform.GL.nvidia.version=550-120
  - --allow=devel
  - --allow=per-app-dev-shm
  - --share=network
  - --share=ipc
  - --socket=wayland
  - --socket=fallback-x11
  - --filesystem=host
  - --filesystem=home
  - --persist=home
  - --env=PYTHONPATH=/app/lib/python3.12/site-packages:\${PYTHONPATH:-}
  - --env=LIBGL_ALWAYS_SOFTWARE=0
  - --env=LIBGL_ALWAYS_INDIRECT=0
  - --env=LIBGL_DEBUG=verbose
  - --env=LIBGL_DRIVERS_PATH=/app/lib/GL/lib/dri
  - --env=OPENGL_VERSION=4.5
  - --env=PS1=[ AMULET_FLATPAK > \w ] >

# Uncomment the following options to increase debug output verbosity in the terminal
#  - --env=PYTHONDEBUG=3
#  - --env=PYTHONVERBOSE=3
#  - --env=PYTHONTRACEMALLOC=10
#  - --env=G_MESSAGES_DEBUG=all

modules:
  - shared-modules/glew/glew.json
  - shared-modules/glu/glu-9.json
  #- pdm.yaml
  #- pyinstaller.yaml
  #- pip-gen.yaml
  - python3-modules.yaml
  - libjpeg8-runtime.yaml
  - amulet_core.yaml
  - name: launcher-script
    buildsystem: simple
    build-commands:
      - mkdir -p /app/bin
      - echo '#!/bin/sh' > /app/bin/amulet
      - echo 'export LIBGL_DRIVERS_PATH="/app/lib/GL/lib/dri"' >> /app/bin/amulet
      - echo 'cd /app && python --verbose -m amulet_map_editor \$1' >> /app/bin/amulet
      - chmod +x /app/bin/amulet
  - name: metainfo-xml
    buildsystem: simple
    build-commands:
      - install -Dm644 ${AFP_XML} -t /app/share/metainfo/
    sources:
      - type: file
        path: ${AFP_XML}
  - name: metainfo-desktop
    buildsystem: simple
    build-commands:
      - install -Dm755 ${AFPBASE}.desktop -t /app/share/applications/
    sources:
      - type: file
        path: ${AFPBASE}.desktop
  - name: metainfo-ico
    buildsystem: simple
    build-commands:
      - install -Dm644 ${AFPBASE}.png -t /app/share/icons/hicolor/256x256/apps/
    sources:
      - type: file
        path: ${AFPBASE}.png

add-extensions:
  org.freedesktop.Platform.GL:
    version: '1.4'
    subdirectories: true
    directory: lib/GL

  org.freedesktop.Platform.GL.nvidia:
    version: '550-120'
    subdirectories: true
    directory: lib/GL
#### <<< Generated by do_this.sh
EOL
    report P "flatpak-pip-generator succeeded!"
    DONE_PIP=true
}

check_version() {
    local version="$1"
    report N "${WHITE}Checking for version number..." #; sleep 2
    if [[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        report P "Using version ${GREEN}$version${WHITE}."
        AFP_VER=$version
    else
        report F "Error on line $2 - '${RED}$version${WHITE}' must be a dotted decimal number."
        read -p "Please enter a valid version number (x to quit): " AFP_VER
        if [ $AFP_VER == "x" ]; then
            echo "Terminating script."
            bye
        fi
        check_version "$AFP_VER" "$2"
    fi
}

# Function to forcefully remove failed objects from old builds if they exist
remove_obj() {
    if [ -f "$1" ]; then
        report N "File \"$1\" located. Removing..."
        rm -f "$1"
        report N "Done."
    elif [ -d "$1" ]; then
        report N "Old version of \"$1\" located. Removing..."
        rm -rf "$1"
        report N "Done."
    fi
}
#clear
####### MAIN SCRIPT #######
## Variable definitions
DEBUG=false
SETVER=false
DONE_PIP=false
PIP_GEN=false
AUTO=false
WRITING_LOG=false
AFPBASE="io.github.evilsupahfly.amulet_flatpak"
AFPREPO="${AFPBASE}-repo"
AFP_YML="${AFPBASE}.yaml"
AFP_XML="${AFPBASE}.metainfo.xml"
AFP_DBG="${AFPBASE}.Debug"
BLD_DIR="${AFPBASE}.build_dir"
FPBDIR=".flatpak-builder"
DO_THIS_YAML=""
I_AM="$0 $@"
PCOUNT=$#
if [ $PCOUNT -eq 0 ]; then
    doHelp
fi

while [[ "$1" != "" ]]; do
    case "$1" in
        --auto)
            AUTO=true
            report N "${WHITE}AUTO=true"
            shift
            ;;
        --version)
            shift
            check_version "$1" "$LINENO"
            shift
            ;;
        --version=*)
            check_version "${1#*=}" "$LINENO"
            shift
            ;;
        --yaml=*)
            DO_THIS_YAML="${1#*=}"
            shift
            ;;
        --debug)
            DEBUG=true
            report N "${WHITE}DEBUG=true"
            shift
            ;;
        --pip-gen)
            PIP_GEN=true
            report N "${WHITE}PIP_GEN=true"
            shift
            ;;
        --help)
            doHelp
            ;;
        *)
            report F "Invalid option: \"$1\""
            bye $LINENO
            ;;
    esac
done

report N "\n${WHITE}--------------------------------\n| PRELIMINARY CHECKS INITIATED |\n--------------------------------"
sleep 2
remove_obj "$BLD_DIR"
remove_obj "$FPBDIR"
remove_obj "amulet-x86_64.flatpak"
sleep 2

# If "--version" was not provided, then read from $AFP_YML
if [[ -z "$AFP_VER" ]]; then
    check_version "$(grep -oP '#version: \K[0-9]+(\.[0-9]+)*' "$AFP_YML")" "$LINENO"
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
        report F "${RED}Installation of flatpak-builder failed. ${YELLOW}Please check your package manager logs for more details."; bye $LINENO
    fi
fi

if ! flatpak list | grep -q "org.flatpak.Builder"; then
    # sleep 2
    if ! flatpak -v install --user -y org.flatpak.Builder; then
        report F "${RED}Fatal Error: ${WHITE}org.flatpak.Builder couldn't be installed."; bye $LINENO
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
        report F "${RED}Installation via package manager failed. \n${WHITE}Try installing manually."; bye $LINENO
    fi
else
    report P "${WHITE}Install verified." #; sleep 2
fi

report N "\n${WHITE}--------------------------------\n| PRELIMINARY CHECKS COMPLETED |\n--------------------------------"
sleep 2

if [[ "$PIP_GEN" == "false" ]]; then
    report N "${WHITE}Skipping ${YELLOW}flatpak-pip-generator${WHITE}, starting ${YELLOW}flatpak-builder${WHITE}."
    # sleep 2
elif [[ "$PIP_GEN" == "true" ]]; then
    doFlatpakPIP
fi

# Attempt to build Frankenstein's Monster - change "tag" when updating to newer Amulet versions
report N "${WHITE}flatpak-builder -vvv --user --rebuild-on-sdk-change --install-deps-from=flathub --add-tag=v$AFP_VER --bundle-sources --repo=$AFPREPO $BLD_DIR $AFP_YML --force-clean\n${GREEN}"
if ! flatpak-builder -vvv --user --rebuild-on-sdk-change --install-deps-from=flathub --add-tag="$AFP_VER" --bundle-sources --repo="$AFPREPO" "$BLD_DIR" "$AFP_YML" --force-clean; then
    report F "flatpak-builder failed."; bye $LINENO
fi

report P "flatpak-builder succeeded!"

# Bundle the contents of the local repository into "amulet-x86_64.flatpak"
report N "${WHITE}flatpak --gpg-homedir=$HOME/.gnupg build-bundle -vvv $AFPREPO amulet-x86_64.flatpak $AFPBASE"
if ! flatpak --gpg-homedir="$HOME/.gnupg" build-bundle -vvv "$AFPREPO" amulet-x86_64.flatpak "$AFPBASE"; then
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

if [ "$AUTO" = "true" ]; then
    report N "\n${WHITE}---------------------\n| AUTO MODE ACTIVE. |\n---------------------\n\n${WHITE}Checking for a previous version..."
    if flatpak list | grep -q "$AFPBASE"; then
        report N "${WHITE}Previous version found. Removing..."
        flatpak --user uninstall -y "$AFPBASE"
        rm -fR /home/$(whoami)/.var/app/$AFPBASE
        report N "${WHITE}Installing new version."
    else
        report N "${RED}Previous version not found. ${WHITE}Installing new version."
    fi
else
    report N "${RED}Auto mode isn't active. ${WHITE}You'll have to manually uninstall and reinstall Amulet Flatpak Edition."
    lastWord
fi

echo -e "\a"

if [ "$DEBUG" = "true" ]; then
    report N "${WHITE}Running DEBUG install...\nflatpak install --include-sdk --include-debug -vvv -y --user amulet-x86_64.flatpak\n"
    if ! flatpak install --include-sdk --include-debug -vvv -y --user amulet-x86_64.flatpak; then
        report F "Amulet Flatpak install failed."; bye $LINENO
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
    #if ! flatpak run --ostree-verbose -vv --command=sh --devel --filesystem="$(pwd)" $AFPBASE; then
    if ! flatpak run --ostree-verbose -vv --command=amulet --devel --filesystem="$(pwd)" $AFPBASE; then
        report F "Amulet Flatpak execution failed."; bye $LINENO
    fi
else
    report N "${WHITE}Auto-Mode active. Starting install." #; sleep 2
    echo -e "${WHITE}flatpak install -y --user amulet-x86_64.flatpak\n"
    if ! flatpak install -y --user amulet-x86_64.flatpak; then
        report F "${RED}flatpak intallation failed."; bye $LINENO
    else
        report P "flatpak installation succeeded."
    fi
    report N "${WHITE}Auto-Mode active. Running: ${YELLOW}flatpak run $AFPBASE${RESET}" #; sleep 2
    if ! flatpak run $AFPBASE; then
        report F "${RED}Amulet launch failed. Please review terminal output."
        bye $LINENO
    fi
fi

report P "Looks like it probably worked. If it didn't, then something is really messed up."
lastWord
