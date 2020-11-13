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
# Created by Cockhash
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
	root_disk=${disk}"p1"
	boot_disk=${disk}"p2"
else
	root_disk=${disk}"1"
	boot_disk=${disk}"2"
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
export root_disk
export boot_disk
export hostname
export root_password
export user
export user_password
export shutdown

echo "------------------------------------------------------"
echo "Setting up mirrors for optimal download - Germany Only"
echo "------------------------------------------------------"

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
curl -s "https://www.archlinux.org/mirrorlist/?country=DE&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' > /etc/pacman.d/mirrorlist
pacman -Syy

echo "--------------------------------------"
echo "--         Formatting disk          --"
echo "--------------------------------------"

# disk prep
sgdisk -Z ${disk} # zap all on disk
sgdisk -a 2048 -o ${disk} # new gpt disk 2048 alignment

# create partitions
sgdisk -n 2:0:+1024M ${disk} # partition 1 (esp), default start block, 1024MB
sgdisk -n 1:0:0 ${disk} # partition 2 (Root), default start, remaining

# set partition types
sgdisk -t 1:8300 ${disk}
sgdisk -t 2:ef00 ${disk}

# label partitions
sgdisk -c 1:"root" ${disk}
sgdisk -c 2:"esp" ${disk}


echo "--------------------------------------"
echo "--       Creating Filesystems       --"
echo "--------------------------------------"

mkfs.ext4 ${root_disk}
mkfs.fat -F32 ${boot_disk}

# mount target
mount ${root_disk} /mnt
mkdir -p /mnt/boot/efi
mount ${boot_disk} /mnt/boot/efi

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

echo "--------------------------------------"
echo "-- Install and configure bootloader --"
echo "--------------------------------------"

# Disable grub delay
sed -i -e 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
sed -i -e 's/GRUB_TIMEOUT=3/GRUB_TIMEOUT=0/g' /etc/default/grub

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub_uefi --recheck --debug
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
grub-mkconfig -o /boot/grub/grub.cfg

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

CHROOT

# Install software from official repositorys
./1_software-pacman.sh

# Install software from unofficial AUR repositorys
#./1_software-aur.sh

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
wget https://raw.githubusercontent.com/XaiMloop/zsh/master/.zshrc -O ~/.zshrc
mkdir -p "$HOME/.zsh"
# Setup Alias in $HOME/zsh/aliasrc
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
# Install awesome terminl font from https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf

# ------------------------------------------------------------------------

#echo -e "\nIncreasing file watcher count"
#
# This prevents a "too many files" error in Visual Studio Code
#echo fs.inotify.max_user_watches=524288 | sudo tee /etc/sysctl.d/40-max-user-watches.conf && sudo sysctl --system

# ------------------------------------------------------------------------

echo -e "\nDisabling Pulse .esd_auth module"

# Pulse audio loads the `esound-protocol` module, which best I can tell is rarely needed.
# That module creates a file called `.esd_auth` in the home directory which I'd prefer to not be there. So...
sudo sed -i 's|load-module module-esound-protocol-unix|#load-module module-esound-protocol-unix|g' /etc/pulse/default.pa

# ------------------------------------------------------------------------

echo -e "\nEnabling Login Display Manager"

sudo systemctl enable gdm

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
