## ArchSetup

This is my daily driver reproducible setup. Just run `./install.sh` to get everything from a fresh install to a fully ready environment.

### How it works

The `install.sh` entry point sources the sub-scripts, ensuring that global variables like the `FAILED` list and `actions_todo` stay consistent across the entire run.

* **packages.sh**: Uses `yay` to install core tools and AUR packages.
* **config.sh**: Manages symlinking for dotfiles (Nvim, Kitty, etc.) and sets up the DaVinci Resolve Distrobox container.
* **services.sh**
* **helper.sh**

### Usage

```bash
chmod +x install.sh
./install.sh

```

### TODO

The script automates most of the heavy lifting, but it will log a list of manual actions at the end. Copy and paste those instructions to finish the setup.
