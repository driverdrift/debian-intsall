#!/usr/bin/env bash
set -euo pipefail
trap 'echo "operation is interrupted"; exit 130' INT

if [ "$EUID" -ne 0 ]; then
  echo "Run with sudo or as root."
  exit 1
fi

REPO_URL="https://github.com/driverdrift/debian-install/archive/main.tar.gz"
WORKDIR="/tmp/debian-install"

skip_confirm=${1:-false}

rm -rf "$WORKDIR" && mkdir -p "$WORKDIR"

command -v wget &>/dev/null || {
	sudo apt-get update -y >/dev/null
	sudo apt-get install wget -y >/dev/null
} || {  echo "Error: can't install wget"
		exit 1
}

echo "Downloading and extracting..."
wget -qO- "$REPO_URL" | tar -xz -C "$WORKDIR" --strip-components=1

cd "$WORKDIR"
echo "Done! Current directory: $(pwd)"

chmod +x main.sh
exec ./main.sh "$skip_confirm"
