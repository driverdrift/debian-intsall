# Boot the original os. 
Enable rescue mode, and reboot to grub and press `esc` quickly via vnc, then press `c` to command line mode, input `ls` to see disks, if the original partition isn't shown, load the proper disk driver.
```
insmod part_gpt  # gpt
insmod part_msdos  # mbr
ls  # check recognized disk condition again
```

For bios mode:
```
set root=(hd1)
chainloader +1
boot
```

For uefi mode (works as well in bios mode):
```
set root=(hd1,gpt2)
linux /install.amd/vmlinuz priority=low  # could press `tab` to see if path autofilled to check correction
initrd /install.amd/initrd.gz
boot
```

# Download the debian cd-rom for a online install or dvd-rom for a offline install.
[Debian Archive Release](https://cdimage.debian.org/cdimage/archive/)  
[Debian Current Release](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/)  

Download and then dd. Follow [this](https://github.com/driverdrift/linux-docs/blob/main/downloader.md) way.

Warning!!!
```
dd if=debian_install.iso of=/dev/vda bs=4M status=progress && sync
```

