#!/bin/bash

# Variables
id=9997
vm_name="rocky-cloudinit-tpl"
memory=4096
cores=2
disk_size="20G"
rocky_image_url="https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-LVM.latest.x86_64.qcow2"
rocky_image_name="Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
storage_pool="local-lvm"
network_bridge="vmbr0"
scsihw_type="virtio-scsi-pci"
cloudinit_drive="local-lvm:cloudinit"

echo "Starting the script to create a Proxmox template with ID $id..."

apt update
apt install libguestfs-tools qemu-utils wget -y

# Download rocky image
echo "Downloading rocky image..."
wget $rocky_image_url -O $rocky_image_name
echo "rocky image downloaded."

# Customize the image to include qemu-guest-agent
echo "Customizing the rocky image to include qemu-guest-agent..."
virt-customize -a $rocky_image_name --install qemu-guest-agent
echo "rocky image has been customized."

# Create the VM
echo "Creating the VM with ID $id..."
qm create $id --name $vm_name --net0 virtio,bridge=$network_bridge --scsihw $scsihw_type --pool Template
echo "VM created."

# Import the disk
echo "Importing the disk to the VM..."
qm importdisk $id $rocky_image_name $storage_pool --format raw
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
echo "VM options set."

# Convert to template
echo "Converting VM to template..."
qm template $id
echo "VM converted to template."

# Clean up
echo "Cleaning up the downloaded image..."
rm $rocky_image_name
echo "Cleanup done."

echo "Script completed. Template with ID $id has been created successfully."
