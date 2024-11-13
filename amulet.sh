#!/bin/bash

RESET="\033[0m" #Normal
YLW="\033[1m\033[1;33m" # Yellow
RED="\033[1m\033[1;91m" # Red
GRN="\033[1m\033[1;92m" # Green
WHT="\033[1m\033[1;97m" # White

AFP="io.github.evilsupahfly.amulet_flatpak"
REPO="https://github.com/EvilSupahFly/Amulet-Flatpak/releases/latest/download/amulet-x86_64.flatpak"
TEMP="/tmp/amulet-flatpak"

report() {
    local status=$1 # F = failure, P = pass, N = notice (neutral)
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [[ "$status" == "F" ]]; then
        echo -e "\n${RED}[$timestamp] ERROR: ${WHT}$message${RESET}"
    elif [[ "$status" == "P" ]]; then
        echo -e "\n${GRN}[$timestamp] SUCCESS: ${WHT}$message${RESET}"
    elif [[ "$status" == "N" ]]; then
        echo -e "\n${YLW}[$timestamp] NOTICE: ${WHT}$message${RESET}"
    fi
}

if ! command -v flatpak &> /dev/null; then
    report F "${RED}Command \"flatpak\" not found.\n${WHT}Checking distribution..."
    # Determine the distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        report P "\n${WHT}Distro determined as ${YLW}$DISTRO${WHT}..."; sleep 2
        report N "\n${WHT}Attempting to install $1 for ${YLW}$DISTRO${WHT}..."; sleep 2
        echo
    fi

    # Determine the package manager and install the package
    case $DISTRO in
        ubuntu|debian)
            sudo apt update && sudo apt install -y flatpak
            ;;
        fedora)
            sudo dnf install -y flatpak
            ;;
        centos|rhel)
            sudo yum install -y flatpak
            ;;
        arch|endeavouros)
            sudo pacman -Syu flatpak
            ;;
        opensuse)
            sudo zypper install -y flatpak
            ;;
        *)
            # Fallback to package manager detection
            report F "$DISTRO not recognized. Attempting to locate suitable package manager."
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y flatpak
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y flatpak
            elif command -v yum &> /dev/null; then
                sudo yum install -y flatpak
            elif command -v pacman &> /dev/null; then
                sudo pacman -Syu flatpak
            elif command -v zypper &> /dev/null; then
                sudo zypper install -y flatpak
            else
                report F "Suitable package manager not found. Please manually install ${YLW}flatpak ${WHT}using your graphical package manager, or contact the author to have $DISTRO support added."
                exit 1
            fi
            ;;
    esac

# Check if Flathub is installed at the user level
report N "${WHT}Checking for Flathub...\n"
if ! flatpak remote-list --user | grep -q "flathub"; then
    report F "${RED}Flathub is not installed. ${WHT}Attempting to add Flathub repository...\n"
    if ! flatpak remote-add --if-not-exists --user --assume-yes flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        report F "${RED}Flathub repository couldn't be added. Try installing the flathub base manually.\n${RESET}"
        exit 1
    else
        report P "${GRN}Flathub repository added successfully.${RESET}\n"
    fi
else
    report N "${GRN}Flathub already installed.\n"
fi

echo -e "${WHT}Checking for Amulet...\n"

if flatpak list | grep -q "$AFP"; then
    report N "${WHT}Previous version found. Removing..."
    flatpak --user uninstall -y "$AFP"
    report N "${WHT}Installing new version."
else
    report N "${RED}Previous version not found. ${WHT}Installing new version."
    mkdir $TEMP
    report N "${RED}Amulet is not installed.\n${WHT}Downloading and installing...\n"
    wget "$REPO" --directory-prefix=$TEMP -O amulet-x86_64.flatpak
    flatpak install -u --assume-yes $TEMP/amulet-x86_64.flatpak
    echo -e "${WHT}Cleaning up...\n"
    rm -f -R $TEMP
    echo -e "${GRN}Launching Amulet...\n${RESET}"
fi

flatpak run "$AFP"
