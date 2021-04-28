#!/usr/bin/env bash

# https://serverfault.com/a/366934/102173
# https://stackoverflow.com/q/3522341/1004587

user=$(id -gn $USER)
echo "User: $user"
echo "SUDO User (as per \$SUDO_USER): $SUDO_USER"
echo "SUDO User ID: $SUDO_UID"

echo "SUDO User (as per \$(logname)): $(logname)"

echo "\$HOME: $HOME"

echo "whoami: $(whoami)"

is_user_root () { [ "${EUID:-$(id -u)}" -eq 0 ]; }

sudo is_user_root || echo "You are not root. Nor have sudo privileges."
