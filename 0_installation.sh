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

#echo "------------------------------------------------------"
#echo "Setting up mirrors for optimal download - Germany Only"
#echo "------------------------------------------------------"
#
#cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
#curl -s "https://www.archlinux.org/mirrorlist/?country=DE&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' > /etc/pacman.d/mirrorlist
pacman -Sy
#
echo "--------------------------------------"
echo "--         Formatting disk          --"
echo "--------------------------------------"

# disk prep
sgdisk -Z ${disk} # zap all on disk
sgdisk -a 2048 -o ${disk} # new gpt disk 2048 alignment

# create partitions
sgdisk -n 3:0:+1024M ${disk} # partition 3 (boot), default start block, 1024MB
sgdisk -n 2:0:+1024M ${disk} # partition 2 (esp), default start block, 1024MB
sgdisk -n 1:0:0 ${disk}      # partition 1 (lvm), default start, remaining

# set partition types
sgdisk -t 1:8300 ${disk}
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

pacstrap -i /mnt base base-devel os-prober efibootmgr grub linux linux-firmware linux-headers vim nano sudo --noconfirm --needed

echo "--------------------------------------"
echo "--    Set-up Internet connection    --"
echo "--------------------------------------"
pacstrap -i /mnt net-tools networkmanager network-manager-applet netctl wireless_tools wpa_supplicant dialog --noconfirm --needed

arch-chroot /mnt /bin/bash <<"CHROOT"

pacman -Sy

echo "--------------------------------------"
echo "-- Install and configure bootloader --"
echo "--------------------------------------"

# Disable grub delay
sed -i -e 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
sed -i -e 's/GRUB_TIMEOUT=3/GRUB_TIMEOUT=0/g' /etc/default/grub

sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=/dev/sda1:main:allow-discards loglevel=3 quiet"/g' /etc/default/grub
sed -i -e 's/#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/g' /etc/default/grub

grub-install --target=x86_64-efi --efi-directory=/boot/esp --bootloader-id=grub_uefi --recheck --debug
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
mkdir /boot/grub/
grub-mkconfig -o /boot/grub/grub.cfg

echo "--------------------------------------"
echo "--        Update mkinitcpio         --"
echo "--------------------------------------"

sed -i -e 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)/g' /etc/mkinitcpio.conf

mkinitcpio -p linux

echo "--------------------------------------"
echo "--    Configure system properly     --"
echo "--------------------------------------"

echo "Setting and generating locale"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
export LANG=en_US.UTF-8

echo "Setting time zone"
ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

echo "Setting core building"
nc=$(grep -c ^processor /proc/cpuinfo)
echo "You have " $nc" cores."
echo "Changing the makeflags for "$nc" cores."
sudo sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$nc"/g' /etc/makepkg.conf
echo "Changing the compression settings for "$nc" cores."
sudo sed -i 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g' /etc/makepkg.conf

echo "Setting hostname"
echo $hostname > /etc/hostname

echo "Setting root password"
echo "root:$root_password" | chpasswd

echo "Setting user account"
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
useradd -m -g users -G wheel $user
echo "$user:$user_password" | chpasswd

echo "Set-up swapfile"
dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab

echo "-------------------------------------------------"
echo "--  Congratulations! Now you're ready to boot  --"
echo "-------------------------------------------------"

echo "--------------------------------------"
echo "--            Optional              --"
echo "--------------------------------------"

# CHROOT closing/new opening because ./1_software-pacman.sh would not be under chrooted /mnt
CHROOT

# Install software from official repositorys
./1_software-pacman.sh

# Install software from unofficial AUR repositorys
./2_software-aur.sh

# "CHROOT" closing/re-opening because ./1_software-pacman.sh would not be under chrooted /mnt
arch-chroot /mnt /bin/bash <<"CHROOT" 

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

su $user

echo "--------------------------------------"
echo "--  FINAL SETUP AND CONFIGURATION   --"
echo "--------------------------------------"

# ------------------------------------------------------------------------

### Set-up ZSH
# Change shell
sudo chsh -s /bin/zsh "$(whoami)"

touch "$HOME/.cache/zshhistory"
# Fetch zsh config
wget https://raw.githubusercontent.com/Cockhash/zsh/main/.zshrc -O ~/.zshrc
mkdir -p "$HOME/.zsh"
# Setup Alias in $HOME/zsh/aliasrc
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

# Install awesome terminl font from https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf

# ------------------------------------------------------------------------

echo -e "\nEnabling Login Display Manager"

sudo systemctl enable sddm

# ------------------------------------------------------------------------

echo -e "\nEnabling bluetooth daemon and setting it to auto-start"

sudo sed -i 's|#AutoEnable=false|AutoEnable=true|g' /etc/bluetooth/main.conf
sudo systemctl enable bluetooth

# ------------------------------------------------------------------------

echo -e "\nEnabling the cups service daemon so we can print"

systemctl enable org.cups.cupsd.service
sudo systemctl disable dhcpcd.service
sudo systemctl enable NetworkManager

# ------------------------------------------------------------------------

sudo su root

# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

echo "-------------------------------------------------"
echo "--                    Done                     --"
echo "-------------------------------------------------"

CHROOT

sleep 3

if [ "$shutdown" = "yes" ]; then
    umount -a
    systemctl poweroff
fi

exit
