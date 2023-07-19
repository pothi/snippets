#!/bin/bash

version=1.0

[ -d ~/.config/systemd/user ] || mkdir -p ~/.config/systemd/user
[ -d ~/.local/bin ] || mkdir -p ~/.local/bin
cd ~/.config/systemd/user || exit 1
wget -q https://github.com/pothi/snippets/raw/main/linux/alert-auto-reboot/alert-auto-reboot.service
wget -q https://raw.githubusercontent.com/pothi/snippets/main/linux/alert-auto-reboot/alert-auto-reboot.timer
cd ~/.local/bin || exit 1
wget -q https://github.com/pothi/snippets/raw/main/linux/alert-auto-reboot/alert-auto-reboot.sh
chmod +x alert-auto-reboot.sh

systemctl --user enable alert-auto-reboot.timer

# if the following error is received...
# Failed to connect to bus: $DBUS_SESSION_BUS_ADDRESS and $XDG_RUNTIME_DIR not defined (consider using --machine=<user>@.host --user to connect to bus of other user)
# you are trying to do the above as sudo (after logging as normal user then root). Login as normal user and then execute the above.

systemctl --user start alert-auto-reboot.timer
systemctl --user enable alert-auto-reboot.service
systemctl --user start alert-auto-reboot.service

# Verify
systemctl --user list-timers


