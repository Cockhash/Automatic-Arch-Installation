#!/usr/bin/env sh

arch-chroot /mnt /bin/bash <<"CHROOT"

echo "--------------------------------------"
echo "--      Install AUR packages        --"
echo "--------------------------------------"

# Install yay (AUR Helper)

cd /tmp
echo "CLOING: YAY"
git clone "https://aur.archlinux.org/yay.git"
cd yay
makepkg -srci --noconfirm

PKGS=(
    # UTILITIES -----------------------------------------------------------
        'timeshift'                 # Backup programm  
        
    # MEDIA ---------------------------------------------------------------
        'rambox-bin'                # Social Media Client-Set
        
    # FONTS
        'ttf-ms-fonts'
        
    # ZSH UTILITIES -------------------------------------------------------
        'zsh-autosuggestions'
        'zsh-syntax-highlighting'
        'autojump'
)

for PKG in "${PKGS[@]}"; do
yay -Syu --noconfirm $PKG
done

CHROOT
