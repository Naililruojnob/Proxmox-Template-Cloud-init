#!/bin/bash

# Variables
id=9999
vm_name="debian-cloudinit-tpl"
memory=4096
cores=2
disk_size="20G"
debian_image_url="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
debian_image_name="debian-12-generic-amd64.qcow2"
storage_pool="local-lvm"
network_bridge="vmbr0"
scsihw_type="virtio-scsi-pci"
cloudinit_drive="local-lvm:cloudinit"

echo "Starting the script to create a Proxmox template with ID $id..."

# Check if wget is installed
if ! command -v wget &> /dev/null; then
    echo "wget could not be found, installing..."
    apt-get update && apt-get install -y wget
    echo "wget has been installed."
else
    echo "wget is already installed."
fi

# Check if virt-customize is installed
if ! command -v virt-customize &> /dev/null; then
    echo "virt-customize could not be found, installing..."
    apt-get update && apt-get install -y libguestfs-tools
    echo "virt-customize has been installed."
else
    echo "virt-customize is already installed."
fi

# Download Debian image
echo "Downloading Debian image..."
wget $debian_image_url -O $debian_image_name
echo "Debian image downloaded."

# Customize the image to include qemu-guest-agent
echo "Customizing the Debian image to include qemu-guest-agent..."
virt-customize -a $debian_image_name --install qemu-guest-agent
echo "Debian image has been customized."

# Create the VM
echo "Creating the VM with ID $id..."
qm create $id --name $vm_name --net0 virtio,bridge=$network_bridge --scsihw $scsihw_type --pool Template
echo "VM created."

# Import the disk
echo "Importing the disk to the VM..."
qm importdisk $id $debian_image_name $storage_pool --format raw
qm set $id --scsi0 $storage_pool:vm-$id-disk-0
echo "Disk imported."

# Resize the disk
echo "Resizing the disk..."
qm disk resize $id scsi0 $disk_size
echo "Disk resized."

# Set VM options
echo "Setting VM options..."
qm set $id --boot order=scsi0
qm set $id --cpu host --cores $cores --memory $memory
qm set $id --ide2 $cloudinit_drive
qm set $id --agent enabled=1
qm set $id --serial0 socket --vga serial0
echo "VM options set."

# Convert to template
echo "Converting VM to template..."
qm template $id
echo "VM converted to template."

# Clean up
echo "Cleaning up the downloaded image..."
rm $debian_image_name
echo "Cleanup done."

echo "Script completed. Template with ID $id has been created successfully."
