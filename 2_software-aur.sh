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
    
        'freeoffice'                # Office Alternative
        'timeshift'                 # Backup programm  
        
    # MEDIA ---------------------------------------------------------------
    
        'rambox-bin'                # Social Media Client-Set
        
    # ZSH Utilities ------------------------------------------------------
    
        'zsh-autosuggestions'
        'zsh-syntax-highlighting'
        'autojump'
)

for PKG in "${PKGS[@]}"; do
yay -Sy --noconfirm $PKG
done

CHROOT
