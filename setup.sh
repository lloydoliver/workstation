#!/bin/bash

sopsver="3.7.1"
gpgkeyid="0x10A16862F507DEB8"

# Call sudo to prompt for password if it's needed before rest of script runs
sudo -v

clear

if [ ! -f /etc/udev/rules.d/70-u2f.rules ];then
  printf "\nInstalling YubiKey udev rules...\n"
  sudo curl -s https://raw.githubusercontent.com/Yubico/libu2f-host/master/70-u2f.rules -o /etc/udev/rules.d/70-u2f.rules
  printf "\n The system must be rebooted. Setup is NOT complete!\n\n \
Please re-run this script after reboot to complete setup!\n\n"
  sleep 5
  sudo reboot
fi

printf "\n\nInstalling Dependencies\n  This may take a while, please wait ...\n"

# Setup some repos and install some required packages
sudo apt-get install -y software-properties-common &>/dev/null
sudo apt-add-repository -y ppa:ansible/ansible &>/dev/null
sudo apt-add-repository -y ppa:yubico/stable &>/dev/null
sudo apt-get update -y &>/dev/null
sudo apt-get install -y ansible gnupg2 gnupg-agent scdaemon pcscd wget &>/dev/null

# Download and install Mozilla SOPS (needed for ansible run)
if [ ! -f sops_"${sopsver}"_amd64.deb ]; then
  wget -q https://github.com/mozilla/sops/releases/download/v"${sopsver}"/sops_"${sopsver}"_amd64.deb
fi
sudo dpkg -i sops_*_amd64.deb &>/dev/null

# Setup GPG config
mkdir ~/.gnupg &>/dev/null
  if [ ! -f ~/.gnupg/gpg.conf ]; then
wget -q -P ~/.gnupg/ https://raw.githubusercontent.com/drduh/config/master/gpg.conf
fi

if [ ! -f ~/.gnupg/gpg-agent.conf ]; then
  wget -q -P ~/.gnupg/ https://raw.githubusercontent.com/drduh/config/master/gpg-agent.conf
fi
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/gpg.conf

# Setup GPG and SSH agent
export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
gpgconf --launch gpg-agent

# Get the GPG public key.
gpg --keyserver hkps://keyserver.ubuntu.com --recv "${gpgkeyid}" &>/dev/null

# In order for ansible to use the GPG key on the Yubikey, we need a way to prompt
# for the PIN. Only way I've found so far is to encrypt then decrypt a file.
# TODO: Find a cleaner way to do this!!!
# First we need to set the trust on the key to stop an additional prompt
(echo 5; echo y; echo save) | gpg --command-fd 0 --no-tty --no-greeting -q --edit-key "${gpgkeyid}" trust

# Now encrypt anything in the file using the key
echo "unlock YubiKey" | gpg --encrypt --armor --recipient "${gpgkeyid}" -o Yubi.key
# decrypt to force the pin entry prompt
gpg --card-status &>/dev/null
gpg --decrypt --armor Yubi.key

printf "\n Done \n\n Running Ansible Playbook ...\n\n"
sleep 1

# Run Ansible
ansible-galaxy install -r requirements.yml
ansible-playbook -i inventory.yml --ask-become-pass main.yml

sudo reboot
