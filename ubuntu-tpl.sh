#!/bin/bash

# Variables
imageURL="https://cloud-images.ubuntu.com/daily/server/noble/current/noble-server-cloudimg-amd64.img"
imageName="jammy-server-cloudimg-amd64-disk-kvm.img"
volumeName="local-lvm"
virtualMachineId="9998"
templateName="ubuntu-cloudinit-tpl"
tmp_cores="2"
tmp_memory="4096"
cpuTypeRequired="host"

# Mise à jour et installation des outils nécessaires
apt update
apt install libguestfs-tools qemu-utils wget -y

# Téléchargement de l'image Ubuntu KVM
rm *.img
wget -O $imageName $imageURL
echo "Ubuntu image downloaded."

# Personnalisation de l'image avec virt-customize
echo "Customizing the image..."
virt-customize -a $imageName --install qemu-guest-agent
echo "Image has been customized."

# Création de la machine virtuelle
echo "Creating the VM with ID $virtualMachineId..."
qm destroy $virtualMachineId 2>/dev/null  # Supprimer une ancienne VM si elle existe
qm create $virtualMachineId --name $templateName --memory $tmp_memory --cores $tmp_cores --net0 virtio,bridge=vmbr0 --pool Template
echo "VM created."

# Importation du disque .img dans Proxmox
echo "Importing the disk to the VM..."
qm importdisk $virtualMachineId $imageName $volumeName --format raw
qm set $virtualMachineId --scsihw virtio-scsi-pci --scsi0 $volumeName:vm-$virtualMachineId-disk-0
echo "Disk imported."

# Configuration de la VM
echo "Setting up VM configuration..."
qm set $virtualMachineId --boot c --bootdisk scsi0
qm set $virtualMachineId --ide2 $volumeName:cloudinit
qm set $virtualMachineId --serial0 socket --vga serial0
qm set $virtualMachineId --ipconfig0 ip=dhcp
qm set $virtualMachineId --cpu cputype=$cpuTypeRequired
echo "VM configuration set."

# Conversion de la VM en template
echo "Converting VM to template..."
qm template $virtualMachineId
echo "VM converted to template."

# Nettoyage
echo "Cleaning up the image..."
rm $imageName
echo "Cleanup done."

echo "Script completed. Template with ID $virtualMachineId has been created successfully."
