#!/bin/bash

#
# This was more of a checklist for myself, but it's handy for limited automation too
#

# Check if the script is running in a Python 3 virtual environment
#if [[ -z "$VIRTUAL_ENV" ]]; then
#    echo "Error: This script must be run inside a Python 3 virtual environment."
#    exit 1
#fi

BOLD="\033[1m"
RESET="\e[0m" #Normal
BGND="\e[40m"
YELLOW="${BOLD}${BGND}\e[1;33m"
RED="${BOLD}${BGND}\e[1;91m"
GREEN="${BOLD}${BGND}\e[1;92m"
WHITE="${BOLD}${BGND}\e[1;97m"


function doFlatpakPIP {
    # Generate everything we need to build Amulet in the Flatpak sandbox
    ./flatpak-pip-generator --requirements-file=requirements.txt --yaml --output=amulet_map_editor

    # Create the initial header for our "proper" manifest
cat << EOL > "amulet.yml"
#### do_this >>> pass 1
id: com.github.amulet_map_editor
name: Amulet Map Editor
runtime: org.freedesktop.Platform
runtime-version: '23.08'
sdk: org.freedesktop.Sdk
sdk-version: '23.08'
inherit-extensions:
  - org.freedesktop.Platform.GL
  - org.gtk.Gtk3theme
  - org.freedesktop.Platform.GL.Debug
  - org.freedesktop.Platform.VAAPI.Intel
inherit-sdk-extensions:
  - org.freedesktop.Sdk.Debug
  - org.freedesktop.Sdk.Extension
  
command: amulet_map_editor

finish-args:
  - --share=network
  - --share=ipc
  - --socket=x11
  - --socket=wayland
  - --device=all
  - --filesystem=home:create
  - --talk-name=org.freedesktop.Notifications
  - --env=DRI_PRIME=1
  - --env=LIBGL_ALWAYS_SOFTWARE="0"
  - --env=LD_LIBRARY_PATH=/app/lib
  - --env=MESA_LOADER_DRIVER_OVERRIDE="host"
  - --env=OPENGL_VERSION=3.3
  - --env=OPENGL_LIB=/usr/lib/x86_64-linux-gnu/libGL.so
  - --env=PYTHON_VERSION=3.11.9
  - --env=WX_PYTHON=/app/lib/python3.11/site-packages/wx
  - --env=WX_PYTHON_VERSION=4.1.1
  - --env=XAPP_GTK3=true
  - --sdk=com.github.amulet_map_editor.Sdk//23.08
  - --runtime=com.github.amulet_map_editor.Platform//23.08

modules:
  - shared-modules/glew/glew.json
  - shared-modules/glu/glu-9.json
  - shared-modules/libappindicator/libappindicator-gtk3-introspection-12.10.json
  - shared-modules/gtk2/gtk2.json
  - shared-modules/dbus-glib/dbus-glib.json
  - shared-modules/pygame/pygame-1.9.6.json

#### <<< do_this pass 1
EOL

    # Add the output from flatpak-pip-generator after cleaning up the temp file
    sed -i "s/modules://g" "amulet_map_editor.yaml"
    sed -i "s/name: amulet_map_editor//g" "amulet_map_editor.yaml"
    cat "amulet_map_editor.yaml" >> "amulet.yml"

    # Throw in some finnishing touches including a .desktop launcher and the Amulet project icon
    cat << EOL >> "amulet.yml"
#### >>> do_this pass 2

icon:
  name: com.github.amulet_map_editor
  src: data/icons/amulet.png

desktop-file:
  name: Amulet Minecraft Editor
  comment: A powerful Minecraft editor
  exec: flatpak run com.github.amulet_map_editor
  icon: amulet
  terminal: true
  type: Application
  categories: [Game, Graphics]
  startup-wm-class: AmuletMapEditor
  
finish:
  # Enable host's drivers for OpenGL
  add-exports:
    - /usr/lib/x86_64-linux-gnu/mesa
  # Allow access to the host's OpenGL drivers
  allow:
    - ipc
    - network
    - x11
    - dri
#### <<< do_this pass 2
EOL

}

if [[ "$1" == "skip" || "$1" == "-skip" || "$1" == "--skip" || "$1" == "-s" ]]; then
    echo -e "${YELLOW}    Skipping the 'flatpak-pip-generator' stage as requested.${RESET}"
    sleep 3
else
    echo -e "${GREEN}    Proceeding with the operation.${RESET}"
    sleep 3
    doFlatpakPIP
fi

# Attempt to build Frankenstein's Monster - change "tag" when updating to newer Amulet versions
flatpak-builder -v --install-deps-from=flathub --mirror-screenshots-url=https://dl.flathub.org/media/ --add-tag=0.10.35 --bundle-sources --repo=amulet_flatpak_repo amulet_build_dir amulet.yml --force-clean

# Bundle the contents of the local repository into "amulet.flatpak"
flatpak build-bundle amulet_flatpak_repo amulet.flatpak com.github.amulet_map_editor

# Install bundle
echo
echo -e "${YELLOW}    To install the Amulet Flatpak, type:"
echo -e "${WHITE}        flatpak install -u amulet.flatpak"

# Run bundle
echo
echo -e "${YELLOW}    To run your install, type:"
echo -e "${WHITE}        flatpak run com.github.amulet_map_editor"

#Uninstall bundle if it doesn't work or you just don't need it
echo
echo -e "${YELLOW}    To uninstall this, type:"
echo -e "${RED}        flatpak uninstall com.github.amulet_map_editor${RESET}"
echo
