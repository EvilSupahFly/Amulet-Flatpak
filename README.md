# Amulet Minecraft Map Editor - Flatpak Edition
My hope, with this project, is to make Amulet easier to install and use for people who aren't used to tinkering with source repositories, or don't have experience with programming, and might not be comfortable attempting to install dependencies and run things from source, or through the terminal.

Since Flatpaks are enabled by default on most distros, and the [linux.com guide](https://www.linux.com/training-tutorials/how-install-and-use-flatpak-linux/) is so well done, there's no need for me to go over the installation and setup of Flatpak. Users of any Ubuntu distribution will need to manually enable Flatpaks however (following the directions in the linux.com guide) as Canoninical has disabled Flatpaks by default in favour of pushing their SnapStore instead. To see why this is a problem, refer to [this blog](https://linuxmint-user-guide.readthedocs.io/en/latest/snap.html) from Linux Mint explaining why Snap is disabled on Mint, and offering their critical take on it.

The `amulet.flatpak` file, available from [Releases](https://github.com/EvilSupahFly/Amulet-Flatpak/releases), is the actual flatpak application and can be downloaded and run locally if you have the Flatpak framework installed by simply running `flatpak install amulet-x86_64.flatpak` from the terminal in the same folder you've saved it to, then run with `flatpak run io.github.evilsupahfly.amulet-flatpak`. Uninstall is equally simplistic, achieved by running `flatpak uninstall io.github.evilsupahfly.amulet-flatpak` or save and run the [amulet.sh](https://github.com/EvilSupahFly/Amulet-Flatpak/blob/testing/amulet.sh) script from this repo, or from the [Releases](https://github.com/EvilSupahFly/Amulet-Flatpak/releases) page..

Assuming this works as intended accross the spectrum of Linux distributions, this project will be handed over to the Amulet team to manage officially.

The initial Flatpak version was sourced from Amulet 0.10.34. With the update to 0.10.36, and the first release of the flatpak, I have included `amulet.sh` which takes care of the foundational framework when run. First, [amulet.sh](https://github.com/EvilSupahFly/Amulet-Flatpak/blob/testing/amulet.sh) will check to see if Flathub is installed, and if not, install it. Then, it checks to see if the Amulet flatpak is already installed, and if so, run it. If not, it will download the latest release from [Releases](https://github.com/EvilSupahFly/Amulet-Flatpak/releases), save the Flatpak file to a temp folder, install it in user mode, remove the temp folder, then run the Amulet Flatpak.

Currently the flatpak release suffers from ~~three~~ ~~two~~ one minor issue:
  - ~~Flickering UI, which plagues upstream Amulet (Linux users only - see [here](https://github.com/Amulet-Team/Amulet-Map-Editor/issues))~~ --> This has been resolved in 0.10.44
  - Missing water and lava textures, which is unique to the flatpak version [issue #7](https://github.com/EvilSupahFly/Amulet-Flatpak/issues/7) and still being investigated.
  - ~~Trying to run on Wayland, unless you have installed Xwayland, is mostly pointless because of some twenty-year-old code in wxPython - expect the error "Unable to access the X Display, is $DISPLAY set properly?"~~* (with update to v0.10.37 this is [now fixed](https://github.com/Amulet-Team/Amulet-Map-Editor/blob/128de1caec6cc7da035b8336cd804d33aa3d5adc/amulet_map_editor/__main__.py#L48).)

![Screenshot from 2024-08-15 23-04-29](https://github.com/user-attachments/assets/c9d42035-67e2-4f0a-8515-a325c0a36532)

If you're feeling ambitious, you can fork or clone this project and try tweaking it. For those brave souls who wish to try, I've written the [do_this.sh](https://github.com/EvilSupahFly/Amulet-Flatpak/blob/testing/do_this.sh) script to help you on your way with a `--help` switch you can pass for usage enlightenment.

The flatpak version has so far been tested on Manjaro, Ubuntu, Kubuntu and Mint. Feedback is most welcome!

~~Fix for textures: I modified [`download_resources.py`](https://github.com/EvilSupahFly/Minecraft-Model-Reader/blob/master/minecraft_model_reader/api/resource_pack/java/download_resources.py#L85) by adding a small `if` loop that examines the path requested, and modifies it if it doesn't match the Flatpak sandbox layout.~~ This broke on the update from 0.10.38 to 0.10.39

# Amulet Flatpak Debug Testing Guide

This guide covers how to install and run the debug build of the Amulet Flatpak and includes instructions for inspecting Python modules, environment variables, and native debug symbols.

---

## 1. Install the Debug Flatpak Bundle

After downloading the debug Flatpak artifact from the CI workflow:

```bash
flatpak install --user --bundle amulet_flatpak_debug_{version}.flatpak
```

---

## 2. Install SDK & Platform Debug Extensions

To access native debug symbols (`strace`, `gdb`, etc.):

```bash
# Install SDK debug symbols
flatpak install flathub org.freedesktop.Sdk.Debug//24.08
```

> These extensions provide symbols for both the runtime libraries and the Python interpreter inside the Flatpak.

---

## 3. Run the Debug Flatpak

You have a few options:

### Normal Run with Python Debug Tools

```bash
flatpak run --devel io.github.evilsupahfly.amulet_flatpak
```

### Run a Shell Inside the Sandbox

```bash
flatpak run --devel --command=bash io.github.evilsupahfly.amulet_flatpak
```

Inside the sandbox shell, you can:

* Access Python via `python3` or `ipython`.
* Inspect environment variables:

```bash
env > sandbox-env.txt
python3 -m site > sandbox-python-site.txt
python3 -m sysconfig > sandbox-sysconfig.txt
```

* Inspect shared libraries:

```bash
ldd $(which python3) > python-ldd.txt
```

* Use `gdb` or `strace` on your app:

```bash
strace -f flatpak run io.github.evilsupahfly.amulet_flatpak
gdb --args flatpak run io.github.evilsupahfly.amulet_flatpak
```

---

## 4. Debug Tips

### 1. Check installed Python Packages

```bash
flatpak run --devel io.github.evilsupahfly.amulet_flatpak python3 -m pip list
```

* Lists all packages installed in the sandbox’s Python environment.
* Confirms that `ipython`, `debugpy`, or any other debug packages are present.

---

### 2. Verify Python Module Import

```bash
flatpak run --devel io.github.evilsupahfly.amulet_flatpak python3 -c "import ipython; print(ipython.__version__)"
```

* Ensures the module can actually be imported.
* Prints the version to verify it matches expectations.

---

### 3. Inspect Python Paths

```bash
flatpak run --devel io.github.evilsupahfly.amulet_flatpak python3 -c "import sys; print('\n'.join(sys.path))"
```

* Shows the directories Python is searching for modules inside the sandbox.
* Useful to spot missing or misrouted site-packages.

---

### 4. Check Python Executable and Sysconfig

```bash
flatpak run --devel io.github.evilsupahfly.amulet_flatpak python3 -m sysconfig
```

* Dumps the Python build configuration and install paths.
* Lets you compare sandbox paths to local VENV paths.

---

### 5. Start an Interactive Debug Shell

```bash
flatpak run --devel --command=ipython io.github.evilsupahfly.amulet_flatpak
```

* Opens an interactive IPython shell with all installed debug packages.
* Handy for live testing and inspecting runtime state.

---

### 6. Full Debug Testing
This section explains how to dump environment variables, Python paths, installed packages, and performs native library inspection for the Python interpreter and key shared objects (.so files). into files:

```bash
# 1. Run the Flatpak in interactive shell mode
flatpak run --devel --command=bash io.github.evilsupahfly.amulet_flatpak

# Once inside the sandbox shell:

# 2. Dump environment variables
env > ~/amulet_debug/sandbox-env.txt

# 3. Dump Python sys.path
python3 -c 'import sys; print("\n".join(sys.path))' > ~/amulet_debug/sandbox-python-path.txt

# 4. Dump Python site-packages directories
python3 -m site > ~/amulet_debug/sandbox-python-site.txt

# 5. List all installed Python packages
python3 -m pip list > ~/amulet_debug/sandbox-pip-list.txt

# 6. Dump Python sysconfig info
python3 -m sysconfig > ~/amulet_debug/sandbox-sysconfig.txt

# 7. Inspect native libraries linked to Python interpreter
ldd $(which python3) > ~/amulet_debug/sandbox-ldd-python.txt

# 8. Inspect native libraries linked to Python extension modules
mkdir -p ~/amulet_debug
echo '--- Checking extension modules ---' > ~/amulet_debug/sandbox-ldd-extensions.txt
for so in $(find $(python3 -c "import site; print(site.getsitepackages()[0])") -name "*.so"); do
  echo "--- $so ---" >> ~/amulet_debug/sandbox-ldd-extensions.txt
  ldd $so >> ~/amulet_debug/sandbox-ldd-extensions.txt
done

# 9. Optional: launch interactive Python shell with debug packages
ipython
```

1. **`sandbox-env.txt`** → captures all environment variables inside the sandbox.
2. **`sandbox-python-path.txt`** → shows `sys.path` so you know where Python looks for modules.
3. **`sandbox-python-site.txt`** → site directories, including where pip-installed modules live.
4. **`sandbox-pip-list.txt`** → lists all Python packages installed in the sandbox.
5. **`sandbox-sysconfig.txt`** → detailed Python configuration info, including library paths and compiler options.
6. **`sandbox-ldd-python.txt`** → lists all native libraries linked to the Python interpreter.
7. **`sandbox-ldd-extensions.txt`** → lists all .so Python extension modules in your site-packages and their linked libraries.

This is basically a **full snapshot of the Python environment inside the Flatpak**, making it easy to compare to a local VENV or spot missing packages.

---

## 5. Cleaning Up

To uninstall the debug Flatpak:

```bash
flatpak uninstall io.github.evilsupahfly.amulet_flatpak
```

To remove debug SDK extensions:

```bash
flatpak uninstall org.freedesktop.Platform.Debug//24.08
flatpak uninstall org.freedesktop.Sdk.Debug//24.08
```

---
README Last updated 13 August, 2025
