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

# Download the debian cd-rom (ISO 9660) for a online install or dvd-rom for a offline install.
[Debian Archive Release](https://cdimage.debian.org/cdimage/archive/)  
[Debian Current Release](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/)  

Download and then dd. Follow [this](https://github.com/driverdrift/linux-docs/blob/main/downloader.md) way.

```
# 将文件精确调整为 1G (1024^3 字节)
truncate -s 1G debian_install.iso
它非常快，因为它并不真的往硬盘里写 300MB 的数据，而是通过改变文件系统的元数据来增加文件的“逻辑大小”（产生所谓的“稀疏文件”）。
实实在在的 0（不是稀疏文件）
fallocate -l 1G debian_install.iso
# 方法 1：保留原文件长度
dd if=debian-13.2.0-amd64-netinst.iso of=test.iso bs=4M conv=notrunc
思路两个：一个是dd到整个救援盘，然后破坏分区，另一个是iso放在原救援盘，如果足够大（用虚拟机测试），然后lookback启动iso，可以重建grub试试
如果验证哈希值时候，有时候需要屏蔽日志
dd if=/dev/vda bs=4M count=196 2>/dev/null | sha256sum
```

Warning!!!
```
dd if=debian_install.iso of=/dev/vda bs=4M status=progress && sync
```

add swap partition
```
sudo fdisk --wipe=never /dev/vdb
```

In pe mode, distinguish disks through size
```
cat /proc/partitions
```
```
swapon /dev/sdX6
free -h
```
