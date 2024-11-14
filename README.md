# Amulet Minecraft Map Editor - Flatpak Edition
My hope, with this project, is to make Amulet easier to install and use for people who aren't used to tinkering with source repositories, or don't have experience with programming, and might not be comfortable attempting to install dependencies and run things from source, or through the terminal.

Since Flatpaks are enabled by default on most distros, and the [linux.com guide](https://www.linux.com/training-tutorials/how-install-and-use-flatpak-linux/) is so well done, there's no need for me to go over the installation and setup of Flatpak. Users of any Ubuntu distribution will need to manually enable Flatpaks however (following the directions in the linux.com guide) as Canoninical has disabled Flatpaks by default in favour of pushing their SnapStore instead. To see why this is a problem, refer to [this blog](https://linuxmint-user-guide.readthedocs.io/en/latest/snap.html) from Linux Mint explaining why Snap is disabled on Mint, and offering their critical take on it.

The `amulet.flatpak` file, available from [Releases](https://github.com/EvilSupahFly/Amulet-Flatpak/releases), is the actual flatpak application and can be downloaded and run locally if you have the Flatpak framework installed by simply running `flatpak install amulet-x86_64.flatpak` from the terminal in the same folder you've saved it to, then run with `flatpak run io.github.evilsupahfly.amulet-flatpak`. Uninstall is equally simplistic, achieved by running `flatpak uninstall io.github.evilsupahfly.amulet-flatpak` or save and run the [amulet.sh](https://github.com/EvilSupahFly/Amulet-Flatpak/blob/testing/amulet.sh) script from this repo, or from the [Releases](https://github.com/EvilSupahFly/Amulet-Flatpak/releases) page..

Assuming this works as intended accross the spectrum of Linux distributions, this project will be handed over to the Amulet team to manage officially.

The initial Flatpak version was sourced from Amulet 0.10.34. With the update to 0.10.36, and the first release of the flatpak, I have included `amulet.sh` which takes care of the foundational framework when run. First, [amulet.sh](https://github.com/EvilSupahFly/Amulet-Flatpak/blob/testing/amulet.sh) will check to see if Flathub is installed, and if not, install it. Then, it checks to see if the Amulet flatpak is already installed, and if so, run it. If not, it will download the latest release from [Releases](https://github.com/EvilSupahFly/Amulet-Flatpak/releases), save the Flatpak file to a temp folder, install it in user mode, remove the temp folder, then run the Amulet Flatpak.

Currently the flatpak release suffers from two minor issues: 
  - flickering UI, which plagues upstream Amulet (Linux users only - see [here](https://github.com/Amulet-Team/Amulet-Map-Editor/issues))
  - missing water and lava textures, which is unique to the flatpak version [issue #7](https://github.com/EvilSupahFly/Amulet-Flatpak/issues/7) and still being investigated.
  - ~~Trying to run on Wayland, unless you have installed Xwayland, is mostly pointless because of some twenty-year-old code in wxPython - expect the error "Unable to access the X Display, is $DISPLAY set properly?"~~* (fixed [here](https://github.com/Amulet-Team/Amulet-Map-Editor/blob/128de1caec6cc7da035b8336cd804d33aa3d5adc/amulet_map_editor/__main__.py#L48).)

![Screenshot from 2024-08-15 23-04-29](https://github.com/user-attachments/assets/c9d42035-67e2-4f0a-8515-a325c0a36532)

If you're feeling ambitious, you can fork or clone this project and try tweaking it. For those brave souls who wish to try, I've written the [do_this.sh](https://github.com/EvilSupahFly/Amulet-Flatpak/blob/testing/do_this.sh) script to help you on your way with a `--help` switch you can pass for usage enlightenment.

The flatpak version has so far been tested on Manjaro, Ubuntu, Kubuntu and Mint. Feedback is most welcome!

I've found a work-around for Wayland users. The modified code is in [my fork of Amulet](https://github.com/EvilSupahFly/Amulet-Map-Editor). Possible side effect however: fonts **may** look like crap.

README Last updated 13 November, 2024
