#!/usr/bin/env sh

arch-chroot /mnt /bin/bash <<"CHROOT"

echo "--------------------------------------"
echo "--      Install AUR packages        --"
echo "--------------------------------------"

# Install paru (AUR Helper)

cd /tmp
echo "CLOING: Paru"
git clone "https://aur.archlinux.org/paru.git"
cd paru
makepkg -srci --noconfirm && cd

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
sudo paru -Syu --noconfirm $PKG
done

CHROOT
