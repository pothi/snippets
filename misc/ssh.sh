#!/bin/bash

# Setup yourself as a user, setup sudo, setup SSH Keys
# Disable root login (for that matter, any logins except yourself)

if id -u pothi &> /dev/null; then
  # If the user 'pothi' is already added (like in Azure), then only change the shell and setup skel files
  chsh --shell /usr/bin/zsh pothi
  cp /etc/skel/.{zshrc,vimrc} /home/pothi/
  chown pothi:pothi /home/pothi/.{zshrc,vimrc}
else
  useradd --shell=/usr/bin/zsh --create-home pothi
  echo "pothi ALL = NOPASSWD : ALL" >> /etc/sudoers.d/pothi && chmod 440 /etc/sudoers.d/pothi
fi

# Set up keys
mkdir /home/pothi/.ssh &> /dev/null
# cp /root/.ssh/authorized_keys /home/pothi/.ssh/
wget -q -O /root/pothi_first_login.pub https://www.tinywp.in/keys/pothi_first_login.pub
cat /root/pothi_first_login.pub >> /home/pothi/.ssh/authorized_keys
rm -f /root/pothi_first_login.pub &> /dev/null
chown -R pothi:pothi /home/pothi/.ssh/
chmod -R 700 /home/pothi/.ssh/

# disable root login, enable password authentication, allow only pothi
sed -i '/^#PermitRootLogin/ s/^#//' /etc/ssh/sshd_config
sed -i '/PermitRootLogin/ s/yes/no/' /etc/ssh/sshd_config

# Some hosts, such as AWS, disable password authentication; let's enable them to let clients / dev login via SFTP/SSH
sed -i '/^#PasswordAuthentication/ s/^#//' /etc/ssh/sshd_config
sed -i '/PasswordAuthentication/ s/no/yes/' /etc/ssh/sshd_config && sed -i '/^#PasswordAuthentication/ s/^#//' /etc/ssh/sshd_config

# TODO: check if AllowUsers line is already present
# Because, if already present, and if you rerun this script, it would create conflict
if ! grep pothi /etc/ssh/sshd_config &> /dev/null ; then
  echo >> /etc/ssh/sshd_config && echo "AllowUsers pothi" >> /etc/ssh/sshd_config
fi

echo 'Time to restart SSH Daemon and test it...'
systemctl restart sshd &> /dev/null
if [ "$?" != 0 ]; then
  service ssh restart
fi
echo 'Done'