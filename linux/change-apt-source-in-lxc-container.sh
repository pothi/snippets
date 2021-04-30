#!/usr/bin/env sh

container=${1:-""}
file_to_exec=change-apt-source.sh

[ -z "$container" ] && { echo "Enter the container name as argument to this script. Exiting now."; exit 1; }

lxc file push ~/bin/$file_to_exec $container/root/
lxc exec $container -- sh -c "chmod +x /root/$file_to_exec && /root/$file_to_exec"
# lxc exec $container -- /root/$file_to_exec
