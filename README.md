Some vps companies don't permit user to mount customized iso, however people concern about the preinstalled os.

- If the rescue-mode is provided and have enough disk to contain netinst.iso (debian-13.2.0 is 784mb), just transfer the rescue-mode disk to an installation media.
Follow [this](./install-from-rescue.md) steps.

- If no rescue-mode is provided or the rescue-mode disk is small to contain netinst.iso, then use the only hard disk to install new os. See [this](./install-from-origin) ways.

Run the code below to install.
```bash
bash <(wget -qO- https://raw.githubusercontent.com/driverdrift/debian-install/main/install.sh)
```
