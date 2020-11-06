#!/usr/bin/env sh

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
    # MEDIA ---------------------------------------------------------------
    
        'lbry-app-bin'              # LBRY Linux Application
        'rambox-bin'                # Social Media Client-Set
    # ZSH Utilities ------------------------------------------------------
    
        'zsh-autosuggestions'
        'zsh-syntax-highlighting'
        'autojump'
        
    # THEMES --------------------------------------------------------------
    
        'materia-gtk-theme'             # Desktop Theme
        'plata-theme'                   # Desktop Theme 
        'tela-icon-theme'               # Desktop Icons
        'papirus-icon-theme'            # Desktop Icons
        'capitaine-cursors'             # Cursor Themes
        'gnome-shell-extension-material-shell-git'   # Material Theme
)

for PKG in "${PKGS[@]}"; do
yay -Sy --noconfirm $PKG
done
