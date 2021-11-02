#!/bin/bash
echo -e "\nInstalling packages from AUR\n"

echo "Cloning into yay.git"
cd ~
git clone "https://aur.archlinux.org/yay.git"
cd ${HOME}/yay
makepkg -si --noconfirm

PKGS=(
'visual-studio-code-bin'
)

for PKG in "${PKGS[@]}"; do
    yay -S --noconfirm $PKG
done

echo -e "\nProceeding\n"
exit
