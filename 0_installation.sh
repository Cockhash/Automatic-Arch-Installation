#!/usr/bin/env sh

#-------------------------------------------------------------------------
#    __  __  _    _    _          _    
#   |  \/  || |  | |  /_\  _ _ __| |_ 
#   | |\/| | \ \/ /  / _ \| '_/ _| '' \
#   |_|  |_|  |__|  /_/ \_\_| \__|_||_|
#  Arch Linux Install and Config Setup
#-------------------------------------------------------------------------

# ATTENTION
#--------------------------------------------------
# Created by cockhash
#--------------------------------------------------
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.
#------------------------------------------------------------------------

echo "--------------------------------------"
echo "--      UEFI / BIOS detection       --"
echo "--------------------------------------"

efivar -l >/dev/null 2>&1

if [[ $? -eq 0 ]]; then
    echo "UEFI detected. Installation will go on."
else
    echo ="BIOS detected. This Installation Script is for UEFI ONLY!"
    echo ="ABORTING"
    exit 1
fi

# sync systemclock
timedatectl set-ntp true

echo "--------------------------------------"
echo "--            Prompts:              --"
echo "--------------------------------------"

lsblk

echo -e "\nPlease enter your drive: /dev/sda, /dev/sdb, /dev/nvme0n1, /dev/nvme0n2 ..."
read disk

if [ "$disk" == "/dev/nvm" ]; then
	lvm_disk=${disk}"p1"
	esp_disk=${disk}"p2"
	boot_disk=${disk}"p3"
else
	lvm_disk=${disk}"1"
	esp_disk=${disk}"2"
	boot_disk=${disk}"3"
fi

echo -e "\nPlease enter hostname:"
read hostname

echo -e "\nPlease enter a ROOT password:"
read -s root_password

echo -e "\nPlease repeate the ROOT password:"
read -s root_password2

# Check both passwords match
if [ "$root_password" != "$root_password2" ]; then
    echo "Passwords do not match"
exit 1
fi

echo -e "\nPlease enter username:"
read user

echo -e "\nPlease enter USER password:"
read -s user_password

echo -e "\nPlease repeate USER password:"
read -s user_password2

# Check both passwords match
if [ "$user_password" != "$user_password2" ]; then
    echo "Passwords do not match"
exit 1
fi

echo -e "\nShutdown after the installation is finished: yes/no"
read shutdown

# export environment variabels
export disk
export lvm_disk
export esp_disk
export boot_disk
export hostname
export root_password
export user
export user_password
export shutdown

echo "--------------------------------------"
echo "--         Formatting disk          --"
echo "--------------------------------------"

# disk prep
sgdisk -Z ${disk} # zap all on disk
sgdisk -a 2048 -o ${disk} # new gpt disk 2048 alignment

# create partitions
sgdisk -n 1:0:+35G ${disk}   # partition 1 (lvm), default start, remaining
sgdisk -n 2:0:+1024M ${disk} # partition 2 (esp), default start block, 1024MB
sgdisk -n 3:0:+1024M ${disk} # partition 3 (boot), default start block, 1024MB

# set partition types
sgdisk -t 1:8e00 ${disk}
sgdisk -t 2:ef00 ${disk}
sgdisk -t 3:8300 ${disk}

# label partitions
sgdisk -c 1:"lvm" ${disk}
sgdisk -c 2:"esp" ${disk}
sgdisk -c 3:"boot" ${disk}

echo "--------------------------------------"
echo "--      Creating encrypted LVM      --"
echo "--------------------------------------"

cryptsetup luksFormat -c aes-xts-plain -y -s 512 -h sha512 ${lvm_disk}
cryptsetup luksOpen ${lvm_disk} lvm

pvcreate /dev/mapper/lvm
vgcreate main /dev/mapper/lvm
lvcreate -l 100%FREE -n lv_root main

modprobe dm-crypt
vgscan
vgchange -ay

echo "--------------------------------------"
echo "--       Creating Filesystems       --"
echo "--------------------------------------"

mkfs.ext4 /dev/main/lv_root
mkfs.fat -F32 ${esp_disk}
mkfs.ext4 ${boot_disk}

# mount target
mount /dev/main/lv_root /mnt
mkdir /mnt/boot
mount ${boot_disk} /mnt/boot
mkdir /mnt/boot/esp
mount ${esp_disk} /mnt/boot/esp

mkdir /mnt/etc
genfstab -Up /mnt >> /mnt/etc/fstab

echo "--------------------------------------"
echo "--    Arch Install on Main Drive    --"
echo "--------------------------------------"

pacstrap -i /mnt base base-devel os-prober efibootmgr grub linux linux-firmware linux-headers vim nano sudo lvm2 cryptdevice --noconfirm --needed

arch-chroot /mnt /bin/bash <<"CHROOT"

pacman -Sy neofetch
neofetch

CHROOT
