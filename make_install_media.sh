make_install_media() {
	
	umount -R /mnt/dev/sdc5
}

_install_grub() {
	local target="$1"  # such as "/dev/sdc"
	echo "target is $target"  # debug
	local mount_path="/mnt${target}5"
	
	mkdir -p "$mount_path"  # mkdir mount dictionary
	mount "${target}5" "$mount_path"  # mount install-iso partition
	
	# install grub for bios mode, system will auto mkdir for boot-directory
	grub-install \
		--target=i386-pc \
		--boot-directory="$mount_path/boot" \
		"$target" >/dev/null
	
	ls "$mount_path/boot/grub/i386-pc" &>/dev/null || { 
		echo "Error: BIOS GRUB directory not found.";
		exit 1;
	}
	echo "BIOS grub installed at: $mount_path/boot/grub/i386-pc"
	
	mkdir -p "$mount_path/boot/efi"
	mount "/${target}2" "$mount_path/boot/efi"
	
	apt-get install grub-efi-amd64 -y >/dev/null
	
	# install grub for uefi mode
	grub-install \
		--target=x86_64-efi \
		--efi-directory=/"$mount_path/boot/efi" \
		--boot-directory="$mount_path/boot" \
		--removable \
		--no-nvram >/dev/null
	
	ls "$mount_path/boot/efi/EFI/BOOT/BOOTX64.EFI" &>/dev/null || { 
		echo "Error: UEFI GRUB directory not found.";
		exit 1;
	}
	echo "UEFI grub installed at: $mount_path/boot/efi/EFI/BOOT/BOOTX64.EFI"
}

_setup_hd_installer_boot() {
	apt-get install aria2 -y >/dev/null
	
	# don't need to dowoload "boot.img.gz" in the samd directory
	# this edition of vmlinuz only support for the latest cd-img, the older edition won't find kernel modules during installation.
	# because neither vmlinuz nor boot.img.gz need to load kernel modules from the matched debian-iso.
	# there are three editions: sid, stable, trixie to choose in link below.
	# loop boot.img.gz is same as boot from vmlinuz&initrd.gz
	# however, boot.img.gz is larger size.
	aria2c -Z -x 16 -s 16 -c --min-split-size=1M -d "$mount_path/boot" https://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/hd-media/{vmlinuz,initrd.gz}
	
	
}

_download_iso() {
	SHA_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA256SUMS"
	
	read ISO SHA <<EOF
		$(wget -qO- "$SHA_URL" \
		| awk '$2 ~ /^debian-[0-9]+\.[0-9]+\.[0-9]+-amd64-netinst\.iso$/ {
			print $2, $1
			exit
		}')
EOF
	
	if [[ -z "$ISO" || -z "$SHA" ]]; then
		echo "Error: No valid ISO found."
		exit 1
	fi
	
	url="${SHA_URL%/SHA256SUMS}/$ISO"
	
	# test if iso exist
	wget --spider -q "$url" \
		|| { echo "URL not reachable or file not found."; exit 1; }
	
	max_retry=20
	count=1
	
	while true; do
		if [ $count -gt $max_retry ]; then
			echo "Reached maximum retry count ($max_retry). Giving up."
			exit 1
		fi
		
		echo "Attempt $count / $max_retry" >&2
		
		if (aria2c -x 16 -s 16 -c --min-split-size=1M -d "$mount_path" "$url" &>/dev/null); then
			if [[ $(sha256sum "$mount_path/$ISO" | awk '{print $1}') == "$SHA" ]]; then
				echo "Download and checksum succeeded."
				break
			else
				exit 1
			fi
		fi
		
		echo "Failed attempt $count, retrying in 1 seconds..." >&2
		count=$((count + 1))
		sleep 1
	done
}
