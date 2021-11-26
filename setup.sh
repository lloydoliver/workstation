#!/bin/bash


printf "\n Installing Dependencies, please wait ...\n"
sudo apt-get install -qq -y software-properties-common git
sudo apt-add-repository -y ppa:ansible/ansible &>/dev/null
sudo apt-add-repository -y ppa:yubico/stable &>/dev/null
sudo apt-get update -qq -y
sudo apt-get install -qq -y ansible curl yubikey-manager yubikey-personalization cryptsetup hopenpgp-tools secure-delete gnupg2 gnupg-agent scdaemon pcscd dirmngr swig libssl-dev libpcsclite-dev wget

wget https://github.com/mozilla/sops/releases/download/v3.7.1/sops_3.7.1_amd64.deb
sudo dpkg -i sops_*_amd64.deb

printf "\n Done \n\n Running Ansible Playbook ...\n\n"
sleep 1

ansible-playbook -i inventory.yml --ask-become-pass main.yml
