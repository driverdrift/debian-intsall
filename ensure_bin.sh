ensure_bin() {
	# Three means loop 3 times at max to prevent looping all the time
	_ensure_bin 3 "$@"
}

_ensure_bin() {
	local max_depth=$1
	shift
	local missing=()
	local failed_pkgs=()
	
	if (( max_depth <= 0 )); then
		echo -e "Error: Maximum recursion depth reached.\nFailed to resolve: $@"
		exit 1
	fi
	
	for cmd in "$@"; do
		if ! command -v "$cmd" &>/dev/null; then
			missing+=("$cmd")
		fi
	done
	
	[ "${#missing[@]}" -eq 0 ] && return 0
	
	apt-get update >/dev/null || exit 1
	echo "Installing missing commands: ${missing[*]}"
	
	for pkg in "${missing[@]}"; do
		if ! apt-get install -y "$pkg" >/dev/null; then
			failed_pkgs+=("$pkg")
		fi
	done
	
	if [ "${#failed_pkgs[@]}" -gt 0 ]; then
		 _fix_failed_bins $((max_depth - 1)) "${failed_pkgs[@]}"
	fi
}

_fix_failed_bins() {
	local depth=$1
	shift
	local failed=("$@")
	local pkg_list=()
	local -A seen_pkgs=()  # otherwise array will only seek num index not string index.
	
	if ! command -v apt-file &>/dev/null; then
		apt-get install apt-file -y >/dev/null || { echo "install apt-file failed"; exit 1; }
	fi
	
	echo "apt-file is updating.."
	apt-file update >/dev/null || exit 1
	
	for bin in "${failed[@]}"; do
		pkg=$(apt-file search -x "/$bin\$" 2>/dev/null | grep -E '/(bin|sbin)/' | head -n1 | cut -d: -f1)
		[[ -n "$pkg" ]] || { echo "can't find the source of ${bin}."; exit 1; }
		
		if [ -z "${seen_pkgs[$pkg]}" ]; then
			pkg_list+=("$pkg")
			seen_pkgs["$pkg"]=1
		fi
	done
	_ensure_bin "$depth" "${pkg_list[@]}"
}

# ensure_bin nginx mkfs.fat aria2c wget curl  # just for debug test
