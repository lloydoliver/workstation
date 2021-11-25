#!/bin/bash

sudo apt-get install -y software-properties-common git
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update -y
sudo apt-get install ansible -y
