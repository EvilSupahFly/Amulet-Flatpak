#!/bin/bash

if [ -z "$1" ]; then
    cmd="sh"
else
    cmd="$1"
fi

flatpak run --ostree-verbose -vv --command="$cmd" --devel --filesystem="$(pwd)" io.github.evilsupahfly.amulet_flatpak
