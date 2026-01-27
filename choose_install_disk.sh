choose_install_disk() {
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
	
	echo "$target"
}
