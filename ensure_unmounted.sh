ensure_unmounted() {
	local target=$1
	local mountpoints=()
	echo "try to umount all partitions for $target"
	mapfile -t mountpoints < <(
		lsblk -ln -o NAME "$target" | tail -n +2 |
		while read part; do
			findmnt -rn -o TARGET --source "/dev/$part"
		done |
		awk '{print length, $0}' | sort -rn | cut -d' ' -f2-
	)

	if (( ${#mountpoints[@]} == 0 )); then
		return 0
	fi
	echo "all mountpoints: ${mountpoints[@]}"
	
	safe_pids=$(ps -eo pid,tty,comm | awk '
		$2 != "?" && $3 ~ /(bash|sshd|login|tmux|screen)/ { print $1 }
	')
	# echo "safe_pids: $(echo "$safe_pids" | tr '\n' ' ')"  # debug
	is_safe_pid() {
		[[ "$1" == "$$" || "$1" == "$PPID" ]] && return 0
		echo "$safe_pids" | grep -qw "$1"
	}
	
	# not mountpoints
	for mp in "${mountpoints[@]}"; do
		echo "try to umount mountpoint: $mp"
		if [[ "$PWD/" == "$mp/"* ]]; then
			cd ~
		fi
		umount -R "$mp" &>/dev/null || {
			#  kill pids of mountpoints safely
			pids=$(lsof +D "$mp" 2>/dev/null | awk 'NR>1 {print $2}' | sort -u)
			[ -n "$pids" ] || continue
			echo "all pids for $mp as mountpoints: $(echo "$pids" | tr '\n' ' ')" 
			
			for pid in $pids; do
				echo "try to kill $pid safely"
				if ! is_safe_pid "$pid"; then
					echo "killing pid $pid ."
					kill -9 $pid >/dev/null
				else
					echo "pid $pid is skipped."
				fi
			done
			
			umount -R "$mp" || {
				echo "Failed to unmount $mp" >&2
				exit 1
			}
		}
	done
}
# target=/dev/sdb  # debug
# ensure_unmounted "$target"
