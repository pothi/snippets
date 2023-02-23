# Alert upon automatic reboot

Unattended-upgrade has an option to reboot the server automatically. Unattended-upgrade runs through a timer that is scheduled to execute around 6AM with a randomized 1 hour delay. It is done through apt-daily-upgrade.timer.

Here, we create another user timer (that runs after apt-daily-upgrade.timer). Since, it is a user timer, we keep the file in `~/.config/systemd/user`.

alert-auto-reboot.sh - contains the code to check for `/var/run/reboot-required` and then sends an email to `$ADMIN_EMAIL` or to `root@localhost` (the default).

alert-auto-reboot.timer - is the actual timer that triggers alert-auto-reboot.service that in turn triggers the above script.

TODO:

Automate deploying all the above three files through ansible or using a script.
