# Amulet Minecraft Map Editor - Flatpak Edition
My hope, with this project, is to make Amulet easier to install and use for people who aren't used to tinkering with source repositories, or don't have experience with programming, and might not be comfortable attempting to install dependencies and run thigs from source, or through the terminal.

Since the [linux.com guide](https://www.linux.com/training-tutorials/how-install-and-use-flatpak-linux/) is so well done, there's no need for me to go over the installation and setup of Flatpak.

The `amulet.flatpak` file, available from [Releases](https://github.com/EvilSupahFly/Amulet-Flatpak/releases), is the actual flatpak application and can be downloaded and run locally if you have the Flatpak framework installed by simply running `flatpak install amulet-x86_64.flatpak` from the terminal in the same folder you've saved it to, then run with `flatpak run io.github.evilsupahfly.amulet-flatpak`. Uninstall is equally simplistic, achieved by running `flatpak uninstall io.github.evilsupahfly.amulet-flatpak` or save and run the `amulet.sh` script available in this repo, in Releases.

Assuming this works as intended accross the spectrum of Linux distributions, this project will be handed over to the Amulet team to manage officially.

The initial Flatpak version was sourced from Amulet 0.10.34. With the update to 0.10.35, and the first release of the flatpak, I have included `amulet.sh` which takes care of almost everything: when run, it will check to see if the Amulet flatpak is already installed, and if so, run it. If not, it will download the latest release from [Releases](https://github.com/EvilSupahFly/Amulet-Flatpak/releases), save the Flatpak file to a temp folder, install it in user mode, remove the temp folder, then run the Amulet Flatpak.

Currently the flatpak release suffers from one minor issue: 
  - flickering UI, which plagues upstream Amulet (see [here](https://github.com/Amulet-Team/Amulet-Map-Editor/issues))

![Screenshot from 2024-08-15 23-04-29](https://github.com/user-attachments/assets/c9d42035-67e2-4f0a-8515-a325c0a36532)

If you're feeling ambitious, you can fork or clone this project and try tweaking it. For those brave souls who wish to try, I've written the `[do_this.sh](https://github.com/EvilSupahFly/Amulet-Flatpak/blob/main/do_this.sh)` script to help you on your way with a `--help` switch you can pass for specifics.

Of course, if you manage to resolve the missing textures, please let me know how you did it!

The flatpak version has so far been tested on Manjaro, Ubuntu, and Mint. Feedback is most welcome!
