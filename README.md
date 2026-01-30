Some vps companies don't permit user to mount customized iso, however people concern about the preinstalled os.

- If the rescue-mode is provided and have enough disk to contain netinst.iso (debian-13.2.0 is 784mb), just transfer the rescue-mode disk to an installation media.
Follow [this](./install-from-rescue.md) steps.

- If no rescue-mode is provided or the rescue-mode disk is small to contain netinst.iso, then use the only hard disk to install new os. See [this](./install-from-origin) ways.

Run the code below to install.
```bash
bash <(wget -qO- https://raw.githubusercontent.com/driverdrift/debian-install/main/install.sh)
```

| Device     | Size   | Type             | FSTYPE   | Mode      | Notes                                                                                         |
| ---------- | ------ | ---------------- | -------- | --------- | --------------------------------------------------------------------------------------------- |
| /dev/sdX1/ | 1M     | BIOS boot        | biosgrub | Bios      | Reserved BIOS boot area, do not format it                                                     |
| /dev/sdX2/ | 100M   | EFI System       | FAT32    | Uefi      | ESP, unencrypted                                                                              |
| /dev/sdX3/ | 512M   | Linux filesystem | ext4     | Bios&Uefi | Boot partition for pure os to install, unencrypted                                            |
| /dev/sdX4/ | -2049M | Linux filesystem | ext4     | Bios&Uefi | /root and /swap partition for pure os to install, encrypted volume, then configure LVM on it. |
| /dev/sdX5/ | 1G     | Linux filesystem | ext4     | Bios&Uefi | Install-media, formatted after installation                                                   |
| /dev/sdX6/ | 1G     | Linux swap       | swap     | Bios&Uefi | Swap Memory for low memory machine during the installation                                    |
