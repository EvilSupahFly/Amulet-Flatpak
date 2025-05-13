# Amulet Minecraft Map Editor - Flatpak Edition
My hope, with this project, is to make Amulet easier to install and use for people who aren't used to tinkering with source repositories, or don't have experience with programming, and might not be comfortable attempting to install dependencies and run things from source, or through the terminal.

Since Flatpaks are enabled by default on most distros, and the [linux.com guide](https://www.linux.com/training-tutorials/how-install-and-use-flatpak-linux/) is so well done, there's no need for me to go over the installation and setup of Flatpak. Users of any Ubuntu distribution will need to manually enable Flatpaks however (following the directions in the linux.com guide) as Canoninical has disabled Flatpaks by default in favour of pushing their SnapStore instead. To see why this is a problem, refer to [this blog](https://linuxmint-user-guide.readthedocs.io/en/latest/snap.html) from Linux Mint explaining why Snap is disabled on Mint, and offering their critical take on it.

The `amulet-x86_64.flatpak` file, available from [Releases](https://github.com/EvilSupahFly/Amulet-Flatpak/releases), is the actual flatpak application and can be downloaded and run locally if you have the Flatpak framework installed by simply running `flatpak install --user amulet-x86_64.flatpak` from the terminal in the same folder you've saved it to, then run with `flatpak run io.github.evilsupahfly.amulet-flatpak`. Uninstall is equally simplistic, achieved by running `flatpak uninstall io.github.evilsupahfly.amulet-flatpak`.

The initial Flatpak version was sourced from Amulet 0.10.34. With the update to 0.10.42, I have switched to using `PEX` to build the application rather than trying to build the Python sources and their respective dependencies into a bundle as a flatpak. Both the .PEX and the .flatpak are available from [Releases](https://github.com/EvilSupahFly/Amulet-Flatpak/releases) so you can either save the Flatpak file to a temp folder, install it in user mode, remove the temp folder, then run the Amulet Flatpak, or you can download the .PEX and run it directly (you may have make the .PEX executable after downloading).

Currently the flatpak release suffers from ~~three~~ ~~two~~ one minor issue: 
  - flickering UI, which plagues upstream Amulet (Linux users only - see [here](https://github.com/Amulet-Team/Amulet-Map-Editor/issues)) - This issue seems to be partially resolved
  - ~~missing water and lava textures, which is unique to the flatpak version [issue #7](https://github.com/EvilSupahFly/Amulet-Flatpak/issues/7) and still being investigated.~~
  - ~~Trying to run on Wayland, unless you have installed Xwayland, is mostly pointless because of some twenty-year-old code in wxPython - expect the error "Unable to access the X Display, is $DISPLAY set properly?"~~

The flatpak version has so far been tested on Manjaro, Ubuntu, Kubuntu and Mint. Feedback is most welcome!

README Last updated 13 May, 2025
