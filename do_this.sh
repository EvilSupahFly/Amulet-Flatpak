#!/bin/bash

# Check if the script is running in a Python 3 virtual environment
#if [[ -z "$VIRTUAL_ENV" ]]; then
#    echo "Error: This script must be run inside a Python 3 virtual environment."
#    exit 1
#fi

./flatpak-pip-generator --requirements-file=req_rev_3.txt --yaml --output=amulet_map_editor

#Dump the header into our "proper" manifest
cat << EOL > "amulet.yml"
#### do_this >>>
id: com.github.amulet_map_editor
runtime: org.freedesktop.Platform
runtime-version: '21.08'
sdk: org.freedesktop.Sdk
sdk-version: '21.08'
command: python -m amulet_map_editor
finish-args:
  - '--share=network'
  - '--socket=x11'
  - '--socket=wayland'
  - '--device=all'
  - '--filesystem=home'
#### <<< do_this
EOL

cat "amulet_map_editor.yaml" >> "amulet.yml"

cat << EOL >> "amulet.yml"
  - name: opengl
    buildsystem: simple
    sources:
      - type: git
        url: 'https://gitlab.freedesktop.org/mesa/mesa.git'
        tag: main
  - name: pyopengl
    buildsystem: simple
    sources:
      - type: pypi
        name: PyOpenGL
        version: 3.1.5
  - name: xapp-gtk3-module
    buildsystem: simple
    sources:
      - type: git
        url: 'https://github.com/linuxmint/xapp.git'
        tag: master
  - name: wayland
    buildsystem: simple
    sources:
      - type: git
        url: 'https://gitlab.freedesktop.org/wayland/wayland.git'
        commit: 5b692b50b9e3d379005633d4ac20068d2069849d
  - name: x11
    buildsystem: simple
    sources:
      - type: git
        url: 'https://gitlab.freedesktop.org/xorg/xserver.git'
        tag: master
  - name: python
    buildsystem: simple
    sources:
      - type: file
        url: 'https://www.python.org/ftp/python/3.9.19/Python-3.9.19.tgz'
        sha256: f5f9ec8088abca9e399c3b62fd8ef31dbd2e1472c0ccb35070d4d136821aaf71
      - *ref_13
  - name: amulet-icon
    buildsystem: simple
    sources:
      - type: file
        path: amulet.ico
name: Amulet Map Editor
finish:
  modules:
    - xapp-gtk3-module
    - mesa
    - wayland
    - x11
  add-extensions:
    - org.freedesktop.Platform.GL
    - org.xapp.xapp-gtk3-module
environment:
  LD_LIBRARY_PATH: /app/lib
  PYTHONPATH: /usr/lib/python3.9/site-packages
  PYTHON_VERSION: 3.9.19
  GTK_MODULES: xapp-gtk3-module
  LIBGL_ALWAYS_SOFTWARE: 1
icon: amulet-icon
EOL

flatpak-builder -v --install-deps-from=flathub --mirror-screenshots-url=https://dl.flathub.org/media/ --add-tag=0.10.35 --bundle-sources --repo=amulet_flatpak_repo amulet_build_dir amulet_testing.yml --force-clean

flatpak build-bundle amulet_flatpak_repo amulet.flatpak com.github.amulet_map_editor

flatpak install amulet.flatpak

flatpak run com.github.amulet_map_editor

#Uninstall if it doesn't work or you just don't need it
#flatpak uninstall com.github.amulet_map_editor

