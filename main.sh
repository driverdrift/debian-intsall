#!/usr/bin/env bash
# This is better than `#!/bin/bash`

set -euo pipefail
# 'e' means error exit(function return or exit not zero)
# 'u' means undefined variable exit
# -o pipefail means an option that exit when anything fails in pipefail rather than only the last one result
trap 'echo "operation is interrupted"; exit 130' INT
# trap 'commands' SIGNALS
# INT means SIGINT usually by ctrl+c
# exit 130 always means ctrl+c 

skip_confirm=false
if [[ "${1-}" =~ ^([Yy][Ee][Ss]|[Yy])$ ]]; then
    skip_confirm=true
fi

echo "Start disk partiton."
source ./disk_partition.sh
apt-get update 1>/dev/null
disk_to_install=$(disk_partition "$skip_confirm")
echo "Disk partiton completed."

echo "Start making install media."
source ./make_install_media.sh
$(make_install_media "$disk_to_install")
echo "Making install media completed."

echo -e "All things completed. You can now exit the rescue mode, \n\
and then poweron your original os to continue installation..."
