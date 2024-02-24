#!/bin/bash

# Execute Terraform
terraform init
terraform apply -auto-approve

# Retrieve IP addresses from Terraform output
IP_1=$(terraform output -raw IPAddr)
IP_2=$(terraform output -raw IPAddr_2)

# Print retrieved IPs
echo "IP_1: $IP_1"
echo "IP_2: $IP_2"

# Generate SSH key if not already exists
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi

# Copy SSH key to the VMs
ssh-copy-id -i ~/.ssh/id_rsa.pub "vagrant@$IP_1"
ssh-copy-id -i ~/.ssh/id_rsa.pub "vagrant@$IP_2"

# Edit Ansible hosts file
echo "[vms]" > hosts
echo "vm1 ansible_host=$IP_1 ansible_user=vagrant" >> hosts
echo "vm2 ansible_host=$IP_2 ansible_user=vagrant" >> hosts

# Execute Ansible playbook to instal docker
# Should be executed after the VMs are up and running
# UPDATE playbook so installs the hole wilde app, not only docker
ansible-playbook -i ./setup/hosts install_docker.yml

# Clean up
terraform destroy -auto-approve
rm -f hosts