#!/bin/bash
echo -e "\nInstalling packages from AUR\n"

echo "Cloning into yay.git"
cd ~
git clone "https://aur.archlinux.org/yay.git"
cd ${HOME}/yay
makepkg -si --noconfirm

PKGS=(
'picom-git'
)

for PKG in "${PKGS[@]}"; do
    yay -S --noconfirm $PKG
done

export PATH=$PATH:~/.local/bin
cp -r $HOME/asrsv/dotfiles/* $HOME/.config/
pip install konsave
konsave -i $HOME/asrsv/kde.knsv
sleep 1
konsave -a kde

echo -e "\nProceeding\n"
exit
