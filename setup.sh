#!/bin/bash

sopsver="3.7.1"
gpgkeyid="0x10A16862F507DEB8"

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
sudo apt-get install -qq -y software-properties-common
sudo apt-add-repository -y ppa:ansible/ansible &>/dev/null
sudo apt-add-repository -y ppa:yubico/stable &>/dev/null
sudo apt-get update -qq -y
sudo apt-get install -qq -y ansible gnupg2 gnupg-agent scdaemon pcscd wget

# Download and install Mozilla SOPS (needed for ansible run)
wget -q https://github.com/mozilla/sops/releases/download/"${sopsver}"/sops_"${sopsver}"_amd64.deb
sudo dpkg -i sops_*_amd64.deb &>/dev/null

# Setup GPG config
mkdir ~/.gnupg &>/dev/null
wget -q -P ~/.gnupg/ https://raw.githubusercontent.com/drduh/config/master/gpg.conf
wget -q -P ~/.gnupg/ https://raw.githubusercontent.com/drduh/config/master/gpg-agent.conf
chmod 600 ~/.gnupg/gpg.conf

# Get the GPG public key.
gpg --keyserver hkps://keyserver.ubuntu.com --recv "${gpgkeyid}" &>/dev/null 

# In order for ansible to use the GPG key on the Yubikey, we need a way to prompt
# for the PIN. Only way I've found so far is to encrypt then decrypt a file.
echo "unlock YubiKey" | gpg --encrypt --armor --recipient "${gpgkeyid}" -o Yubi.key
gpg --decrypt --armor Yubi.key &>/dev/null


printf "\n Done \n\n Running Ansible Playbook ...\n\n"
sleep 1

# Run Ansible
ansible-playbook -i inventory.yml --ask-become-pass main.yml
