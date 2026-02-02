make_install_media() {
	_install_grub "$1"
	_setup_hd_installer_boot
	_download_iso
	source ./grub-sample/hd-installer-grub-sample.cfg
	_fix_path
	echo umounting -R "$1"
	source ./ensure_unmounted.sh
	ensure_unmounted "$1"
	rm -rf "$mount_path" "$iso_mount_path"
}

_install_grub() {
	local target="$1"  # such as "/dev/sdc"
	echo "target is $target"  # debug
	mount_path="/tmp/debian-install/mnt"
	
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
		
		if (aria2c -x 16 -s 16 -c --min-split-size=1M  --summary-interval=0 --console-log-level=error \
		--file-allocation=trunc -d "$mount_path" "$url" "$url" 2>/dev/null); then
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

_fix_path(){
	iso_mount_path="$mount_path/iso_mnt"  # Temporary mount point for the ISO
	
	# Create necessary directories:
	# - $mount_path/isolinux: for splash.png
	# - $mount_path/boot/grub/theme: for theme images (hl_*.png)
	mkdir -p "$iso_mount_path" "$mount_path/isolinux" "$mount_path/boot/grub/theme"
	
	# Mount the ISO to extract files
	mount "$mount_path/$ISO" "$iso_mount_path"

	# Font file (font.pf2) is commented out
	# Reason: local GRUB already generated a unicode font, so no need to copy
	# If you do copy font.pf2 from the ISO, it must go to GRUB's current root (/) 
	# because $prefix in grub.cfg points to /, otherwise loadfont will not find it
	# grub refers:
	# font=\$prefix/font.pf2
	# cp "$iso_mount_path/boot/grub/font.pf2" "$mount_path"

	# Reason: theme uses desktop-image: "/isolinux/splash.png"
	# GRUB root is current partition, not ISO root, so we need this copy
	# Otherwise grub will inform that "error: file `/isolinux/splash.png' not found."
	cp "$iso_mount_path/isolinux/splash.png" "$mount_path/isolinux"

	# Copy theme highlight images (hl_*.png)
	# Reason: theme references hl_*.png for selected items
	# GRUB root is current partition, not ISO root, so we need this copy
	cp $iso_mount_path/boot/grub/theme/hl_*.png "$mount_path/boot/grub/theme"  # no "" for hl_*.png
}
