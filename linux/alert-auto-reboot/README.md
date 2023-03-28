# Alert upon automatic reboot

Unattended-upgrade has an option to reboot the server automatically. Unattended-upgrade runs through a timer that is scheduled to execute around 6AM with a randomized 1 hour delay. It is done through apt-daily-upgrade.timer.

Here, we create another user timer (that runs after apt-daily-upgrade.timer). Since, it is a user timer, we keep the file in `~/.config/systemd/user`.

alert-auto-reboot.sh - contains the code to check for `/var/run/reboot-required` and then sends an email to `$ADMIN_EMAIL` or to `root@localhost` (the default).

alert-auto-reboot.timer - is the actual timer that triggers alert-auto-reboot.service that in turn triggers the above script.

TODO:

Automate deploying all the above three files through ansible or using a script.

```

[ -d ~/.config/systemd/user ] || mkdir -p ~/.config/systemd/user
[ -d ~/.local/bin ] || mkdir -p ~/.local/bin
cd ~/.config/systemd/user || exit 1
wget -q https://github.com/pothi/snippets/raw/main/linux/alert-auto-reboot/alert-auto-reboot.service
wget -q https://raw.githubusercontent.com/pothi/snippets/main/linux/alert-auto-reboot/alert-auto-reboot.timer
cd ~/.local/bin || exit 1
wget -q https://github.com/pothi/snippets/raw/main/linux/alert-auto-reboot/alert-auto-reboot.sh
chmod +x alert-auto-reboot.sh

systemctl --user enable alert-auto-reboot.timer
systemctl --user start alert-auto-reboot.timer
systemctl --user enable alert-auto-reboot.service
systemctl --user start alert-auto-reboot.service

# Verify
systemctl --user list-timers

```
