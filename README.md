Some vps companies don't permit user to mount customized iso, however people concern about the preinstalled os.

- If the rescue-mode is provided and have access for internet, just transfer the original-os disk to an installation media. Follow [these](./install-from-rescue.md) steps.  
If rescue-mode can't apt install packages due to outdated signature. Follow [these](https://github.com/driverdrift/main/archieved-sources.md) steps to solve it.
- If no rescue-mode is provided or the rescue-mode disk is small to contain netinst.iso, then use the only hard disk to install new os. See [these](./install-from-origin) ways.

Run the code below to install automatically.
```bash
bash <(wget -qO- https://raw.githubusercontent.com/driverdrift/debian-install/main/install.sh) y

```
Or run the code below to install manually.
```bash
bash <(wget -qO- https://raw.githubusercontent.com/driverdrift/debian-install/main/install.sh)

```

Partition sample
| Partition  | Size   | Type             | FSTYPE   | Mode      | Use as                                                                                        |
| :--------- | -----: | :--------------- | :------- | :-------- | :-------------------------------------------------------------------------------------------- |
| /dev/sdX1/ | 1M     | BIOS boot        | biosgrub | Bios      | Reserved BIOS boot area, do not format it                                                     |
| /dev/sdX2/ | 100M   | EFI System       | FAT32    | Uefi      | ESP, unencrypted                                                                              |
| /dev/sdX3/ | 512M   | Linux filesystem | ext4     | Bios&Uefi | Boot partition for pure os to install, unencrypted                                            |
| /dev/sdX4/ | -2049M | Linux filesystem | ext4     | Bios&Uefi | /root and /swap partition for pure os to install, encrypted volume, then configure LVM on it. |
| /dev/sdX5/ | 1G     | Linux filesystem | ext4     | Bios&Uefi | Install-media, encrypted after installation                                                   |
| /dev/sdX6/ | 1G     | Linux swap       | swap     | Bios&Uefi | Swap memory for low memory machine during the installation, encrypted after installation      |
