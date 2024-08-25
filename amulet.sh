#!/bin/bash

AFP="com.github.amulet_map_editor"

if flatpak list | grep -q "$AFP"; then
    echo "$AFP is installed. Launching..."
    flatpak run "$AFP"
else
    echo "$AFP is not installed."
    echo "Please visit https://github.com/EvilSupahFly/Amulet-Flatpak/releases to download it."
fi

flatpak run "$AFP"

