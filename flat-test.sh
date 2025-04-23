#!/bin/bash

# Define the directory to search
if [ -z "$1" ]; then
    search_directory="/home/seann/.var/app/io.github.evilsupahfly.amulet_flatpak/data/AmuletMapEditor"
else
    search_directory="$1"
fi

# Load filenames into an array
files_to_search=("water.png" "lava.png")

# Function to search for files
search_files() {
    local file=$1
    if find "$search_directory" -name "$file" | grep -q .; then
        echo "Found: $file"
    else
        echo "Search for $file did not return any results."
    fi
}

# Loop through the array and call the search function
for file in "${files_to_search[@]}"; do
    search_files "$file"
done

