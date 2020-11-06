#!/usr/bin/env zsh

echo -e "\nSetting up theming"

# enable user-shell-theme
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com

# install material theme
gnome-extensions enable material-shell@papyelgringo

# change icon theme
gsettings set org.gnome.desktop.interface icon-theme "Tela-dark"

# change shell theme
gsettings set org.gnome.shell.extensions.user-theme name "Plata-Noir-Compact"

# change cursor theme
gsettings set org.gnome.desktop.interface cursor-theme "capitaine-cursors"

# change application theme
gsettings set org.gnome.desktop.interface gtk-theme "Plata-Noir-Compact"

# scale for external monitor
gsettings set org.gnome.desktop.interface scaling-factor 2

# change wallpaper
cd /home/"$(whoami)"/Pictures && wget https://wallpaperaccess.com/full/1776164.jpg && mv 1776164.jpg arch-wallpaper.jpg
gsettings set org.gnome.desktop.background picture-uri file:///home/"$(whoami)"/Pictures/arch-wallpaper.jpg

# change screenshot directory
mkdir /home/"$(whoami)"/Pictures/Screenshots
gsettings set org.gnome.gnome-screenshot auto-save-directory 'file:////home/"$(whoami)"/Pictures/Screenshots'
## remove default screenshot option (key: print)
## create new shortcut; Name: 'Screenshot (own directory)'; Key: 'Print'; Command: 'gnome-screenshot';
