#!/bin/bash
echo "---------------------"
echo "Setting up Networking"
echo "---------------------"
pacman -S networkmanager dhclient --noconfirm --needed
systemctl enable --now NetworkManager
echo "---------------------------------"
echo "Installing crap in the background"
echo "---------------------------------"
pacman -S --noconfirm pacman-contrib curl
pacman -S --noconfirm reflector rsync
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

nc=$(grep -c ^processor /proc/cpuinfo)
echo "Your core count is " $nc" #C479G."
echo "-------------------------------------------------"
echo "Changing stuff"
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -gt 8000000 ]]; then
sudo sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$nc"/g' /etc/makepkg.conf
echo "Setting up stuff"
sudo sed -i 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g' /etc/makepkg.conf
fi
echo "--------------------------"
echo "Setting locale as en_us/FI"
echo "--------------------------"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone Europe/Helsinki
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"

localectl --no-ask-password set-keymap us

sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

sed -i 's/^#Para/Para/' /etc/pacman.conf

sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm

echo -e "\nInstalling base system\n"

PKGS=(
'autoconf'
'automake'
'base'
'bash-completion'
'btrfs-progs'
'os-prober'
'dosfstools'
'efibootmgr'
'exfat-utils'
'extra-cmake-modules'
'git'
'gptfdisk'
'grub'
'htop'
'libdvdcss'
'libnewt'
'libtool'
'linux'
'linux-firmware'
'linux-headers'
'make'
'nano'
'neofetch'
'networkmanager'
'openssh'
'pacman-contrib'
'patch'
'pkgconf'
'pulseaudio'
'pulseaudio-alsa'
'pulseaudio-bluetooth'
'sudo'
'unzip'
'zip'
)

for PKG in "${PKGS[@]}"; do
    echo "Installing a bit of this and that: ${PKG}"
    sudo pacman -S "$PKG" --noconfirm --needed
done

proc_type=$(lscpu | awk '/Identification:/ {print $3}')
case "$proc_type" in
	GenuineIntel)
		print "Installing Intel stuff"
		pacman -S --noconfirm intel-ucode
		proc_ucode=intel-ucode.img
		;;
	AuthenticAMD)
		print "Installing AMD stuff"
		pacman -S --noconfirm amd-ucode
		proc_ucode=amd-ucode.img
		;;
esac	

if lspci | grep -E "NVIDIA"; then
    pacman -S nvidia --noconfirm --needed
	nvidia-xconfig
elif lspci | grep -E "AMD"; then
    pacman -S xf86-video-amdgpu --noconfirm --needed
elif lspci | grep -E "Integrated Graphics"; then
    pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils --needed --noconfirm
fi

echo -e "\nProceeding\n"
if ! source install.conf; then
	read -p "Enter a username:" username
echo "username=$username" >> ${HOME}/asrsv/install.conf
fi
if [ $(whoami) = "root"  ];
then
    useradd -m -G wheel,libvirt -s /bin/bash $username 
	passwd $username
	cp -R /root/asrsv /home/$username/
    chown -R $username: /home/$username/asrsv
	read -p "Enter a hostname:" nameofmachine
	echo $nameofmachine > /etc/hostname
else
	echo "Something went wrong, but you can still proceed to yay installs."
fi

