#!/bin/bash

version=1.0


systemctl --user stop alert-auto-reboot.timer

# if the following error is received...
# Failed to connect to bus: $DBUS_SESSION_BUS_ADDRESS and $XDG_RUNTIME_DIR not defined (consider using --machine=<user>@.host --user to connect to bus of other user)
# you are trying to do the above as sudo (after logging as normal user then root). Login as normal user and then execute the above.

systemctl --user disable alert-auto-reboot.timer
systemctl --user stop alert-auto-reboot.service
systemctl --user disable alert-auto-reboot.service

