disk_partition() {
	local skip_confirm=${1:-false}
	
	# find rescue-os disk
	sysdisk=$(lsblk -rno NAME,TYPE -s "$(findmnt -n -o SOURCE /)" | awk '$2=="disk"{print $1}')
	# find original system disk which are going to install pure os.
	mapfile -t disks < <(lsblk -dn -o NAME | grep -Ev "^($sysdisk|sr[0-9]+)$")
	
	case ${#disks[@]} in
		0)
			echo "There is no additional disk detected to install os" >&2
			exit 1
			;;
		1)
			target="/dev/${disks[0]}"
			echo "select $target automatically" >&2
			;;
		*)
			echo "There are many disks, please select the disk you want to install os" >&2
			select d in "${disks[@]}"; do
				[ -n "$d" ] && { target="/dev/$d"; break; }
			done
			;;
	esac
	
	if [ "$skip_confirm" = false ]; then
		read -rp "Are you sure to foramt $target ? [No by default] (yes/y to confirm): " ans
		ans=$(printf '%s' "$ans" | xargs)
		[[ "$ans" =~ ^([Yy]|[Yy][Ee][Ss])$ ]] || exit 1
	fi

	source ./ensure_unmounted.sh
	ensure_unmounted "$target" >&2
	
	(
		echo -e "g\n					\
			n\n\n\n+1M\nt\n4\n			\
			n\n\n\n+20M\nt\n\nuefi\n	\
			n\n\n\n+512M\n				\
			n\n\n\n-2049M\n				\
			n\n\n\n+1G\n				\
			n\n\n\n\nt\n\nswap\n		\
			w\n"
	) | fdisk $target 1>/dev/null

	sync && partx -u $target && echo "inform system fo flush partiton table" >&2
	
	apt-get install dosfstools -y 1>/dev/null

	(
		mkfs.vfat -F32 -I -n ESP "${target}2"  # uefi partition for new os
		mkfs.ext4 -F -L boot "${target}3"  # boot partition for new os
		mkfs.ext4 -F -L vg "${target}4"  # root partition for new os
		mkfs.ext4 -F -L install-iso "${target}5"  # root partition for install-iso and /boot
		mkswap "${target}6"  # swap partition for low memory machine
	) 1>/dev/null
	
	echo "$target"
}
