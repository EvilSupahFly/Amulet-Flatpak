#!/bin/bash

# Check if the script is running in a Python 3 virtual environment
#if [[ -z "$VIRTUAL_ENV" ]]; then
#    echo "Error: This script must be run inside a Python 3 virtual environment."
#    exit 1
#fi

./flatpak-pip-generator --requirements-file=req_rev_3.txt --yaml --output=amulet_map_editor

#Dump the header into our "proper" manifest
cat << EOL > "amulet.yml"
runtime: org.freedesktop.Platform
runtime-version: '21.08'
sdk: org.freedesktop.Sdk
sdk-version: '21.08'

finish-args:
  - --share=network
  - --socket=x11
  - --socket=wayland
  - --device=all
  - --filesystem=home
  - --env=PYTHONPATH=/app/lib/python3.9/site-packages
  
finish:
  # OpenGL support
  add-extensions:
    - org.freedesktop.Platform.GL
  # xapp-gtk3-module support
  add-extensions:
    - org.xapp.xapp-gtk3-module

EOL

cat "amulet_map_editor.yaml" >> "amulet.yml"

flatpak-builder -v --install-deps-from=flathub --mirror-screenshots-url=https://dl.flathub.org/media/ --add-tag=0.10.35 --bundle-sources --repo=amulet_flatpak_repo amulet_build_dir amulet_testing.yml --system --keep-build-dirs --force-clean

flatpak build-bundle amulet_flatpak_repo amulet.flatpak com.github.amulet_map_editor

flatpak install amulet.flatpak

flatpak run com.github.amulet_map_editor

#Uninstall if it doesn't work or you just don't need it
#flatpak uninstall com.github.amulet_map_editor

