# Amulet Minecraft Map Editor - Flatpak Edition
My hope, with this project, is to make Amulet easier to install and use for people who aren't used to tinkering with source repositories, or don't have experience with programming, and might not be comfortable attempting to install dependencies and run thigs from source, or through the terminal.

Since the guide at https://www.linux.com/training-tutorials/how-install-and-use-flatpak-linux/ is so well done, there's no need for me to go over the installation and setup of Flatpak.

The `amulet.flatpak` file, available from [Releases](https://github.com/EvilSupahFly/Amulet-Flatpak/releases), is the actual flatpak application and can be downloaded and run locally if you have the Flatpak framework installed by simply running `flatpak install amulet.flatpak` from the terminal in the same folder you've saved it to, then run with `flatpak run io.github.evilsupahfly.amulet-flatpak`. Uninstall is equally simplistic, achieved by running `flatpak uninstall io.github.evilsupahfly.amulet-flatpak` or save and run the `amulet.sh` script available in this repo, in Releases.

Assuming this works as intended accross the spectrum of Linux distributions, this project will be handed over to the Amulet team to manage officially.

The initial Flatpak version was sourced from Amulet 0.10.34. With the update to 0.10.35, and the first release of the flatpak, I have included `amulet.sh` which takes care of almost everything: when run, it will check to see if the Amulet flatpak is already installed, and if so, run it. If not, it will download the latest release from [Releases](https://github.com/EvilSupahFly/Amulet-Flatpak/releases), save the Flatpak file to a temp folder, install it in user mode, remove the temp folder, then run the Amulet Flatpak.

Currently the flatpak release suffers from a number of issues that plague upstream Amulet, which you can see [here](https://github.com/Amulet-Team/Amulet-Map-Editor/issues). Once the issues are resolved upstream, the flatpak will be updated accordingly.

![Screenshot from 2024-08-11 22-26-11](https://github.com/user-attachments/assets/a45f074f-85ee-40f4-b624-987d9506258b)

![Screenshot from 2024-08-11 22-33-44](https://github.com/user-attachments/assets/d9526f27-d74d-4c1a-8be0-37d14387feb9)

![Screenshot from 2024-08-15 23-04-29](https://github.com/user-attachments/assets/c9d42035-67e2-4f0a-8515-a325c0a36532)
