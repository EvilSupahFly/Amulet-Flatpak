#!/bin/bash

#
# This was more of a checklist for myself, but it's handy for limited automation too
#

# Check if the script is running in a Python 3 virtual environment
#if [[ -z "$VIRTUAL_ENV" ]]; then
#    echo "Error: This script must be run inside a Python 3 virtual environment."
#    exit 1
#fi

# Generate everything we need to build Amulet in the Flatpak sandbox
./flatpak-pip-generator --requirements-file=req_rev_3.txt --yaml --output=amulet_map_editor

# Create the initial header for our "proper" manifest
cat << EOL > "amulet.yml"
#### do_this >>> pass 1
id: com.github.amulet_map_editor
name: Amulet Map Editor
runtime: org.freedesktop.Platform
runtime-version: '23.08'
sdk: org.freedesktop.Sdk
sdk-version: '23.08'
add-build-extensions:
  - org.freedesktop.Platform.GL.default
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

#### <<< do_this pass 1
EOL

# Add the output from flatpak-pip-generator after removing the trailing "name:" designator
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
#### <<< do_this pass 2
EOL

# Attempt to build Frankenstein's Monster - change "tag" when updating to newer Amulet versions
flatpak-builder -v --install-deps-from=flathub --mirror-screenshots-url=https://dl.flathub.org/media/ --add-tag=0.10.35 --bundle-sources --repo=amulet_flatpak_repo amulet_build_dir amulet.yml --force-clean

# Bundle the contents of the local repository into "amulet.flatpak"
flatpak build-bundle amulet_flatpak_repo amulet.flatpak com.github.amulet_map_editor

# Install bundle
echo "To install the Amulet Flatpak, type:"
echo "flatpak install amulet.flatpak"

# Run bundle
echo "To install your install, type:"
echo "flatpak run com.github.amulet_map_editor"

#Uninstall bundle if it doesn't work or you just don't need it
echo "To uninstall this, type:"
echo "flatpak uninstall com.github.amulet_map_editor"