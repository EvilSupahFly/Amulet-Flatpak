#!/bin/bash

# Function to install yq
install_yq() {
    echo "Attempting to install yq..."
    
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y yq
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y yq
    elif command -v yum &>/dev/null; then
        sudo yum install -y epel-release && sudo yum install -y yq
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm yq
    elif command -v brew &>/dev/null; then
        brew install yq
    elif command -v zypper &>/dev/null; then
        sudo zypper install -y yq
    else
        echo "Unsupported package manager. Please install 'yq' manually."
        exit 1
    fi
}

# Function to install pip
install_pip() {
    echo "Attempting to install pip..."
    
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y python3-pip
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y python3-pip
    elif command -v yum &>/dev/null; then
        sudo yum install -y python3-pip
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm python-pip
    elif command -v brew &>/dev/null; then
        brew install python
    elif command -v zypper &>/dev/null; then
        sudo zypper install -y python3-pip
    else
        echo "Unsupported package manager. Please install 'pip' manually."
        exit 1
    fi
}

# Ensure yq is installed
if ! command -v yq &>/dev/null; then
    echo "Error: 'yq' is not installed."
    read -p "Would you like to install yq now? (y/N): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        install_yq
    else
        echo "Please install 'yq' manually and rerun the script."
        exit 1
    fi
fi

# Ensure pip is installed
if ! command -v pip &>/dev/null; then
    echo "Error: 'pip' is not installed."
    read -p "Would you like to install pip now? (y/N): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        install_pip
    else
        echo "Please install 'pip' manually and rerun the script."
        exit 1
    fi
fi

# Check if a YAML file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <yaml_file>"
    exit 1
fi

YAML_FILE="$1"

# Check if the YAML file exists
if [ ! -f "$YAML_FILE" ]; then
    echo "Error: File '$YAML_FILE' not found!"
    exit 1
fi

# Extract file paths from YAML and handle missing values
FILES=$(yq '.packages[] // empty' "$YAML_FILE")

# Ensure FILES is not empty or null
if [ -z "$FILES" ]; then
    echo "No valid packages found in $YAML_FILE"
    exit 1
fi

# Install packages from wheel and tar.gz files
INSTALLED=0
for FILE in $FILES; do
    if [[ "$FILE" == *.whl || "$FILE" == *.tar.gz ]]; then
        if [ -f "$FILE" ]; then
            echo "Installing: $FILE"
            pip install "$FILE"
            INSTALLED=1
        else
            echo "Warning: File '$FILE' not found. Skipping..."
        fi
    fi
done

# Check if any packages were installed
if [ "$INSTALLED" -eq 0 ]; then
    echo "No valid .whl or .tar.gz files found in $YAML_FILE"
fi

