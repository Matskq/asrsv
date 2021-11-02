#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "----------------------------------------"
echo "                __          __          "
echo "  _____ _____ _/  |_  _____|  | ________"
echo " /     \\__  \\   __\/  ___/  |/ / ____/"
echo "|  Y Y  \/ __ \|  |  \___ \|    < <_|  |"
echo "|__|_|  (____  /__| /____  >__|_ \__   |"
echo "      \/     \/          \/     \/  |__|"
echo "                                        "
echo "----------------------------------------"

iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm pacman-contrib terminus-font
setfont ter-v22b
sed -i 's/^#Para/Para/' /etc/pacman.conf
pacman -S --noconfirm reflector rsync grub
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt


echo -e "\nInstalling stuff...\n$HR"
pacman -S --noconfirm gptfdisk btrfs-progs

echo "-----------------------"
echo "Select a disk to format"
echo "-----------------------"
lsblk
echo "Enter a disk to use for the OS, such as /dev/sda"
read DISK
echo "Warning, all data on this disk will be wiped"
read -p "do you want to continue (y/n):" formatdisk
case $formatdisk in

y|Y|yes|Yes|YES)
echo "------------------------"
echo -e "\nPreparing disk\n$HR"
echo "------------------------"

sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}

sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK}
sgdisk -n 2::+100M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK}
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK}
if [[ ! -d "/sys/firmware/efi" ]]; then
    sgdisk -A 1:set:2 ${DISK}
fi

echo -e "\nSetting up filesystems...\n$HR"
if [[ ${DISK} =~ "nvme" ]]; then
mkfs.vfat -F32 -n "EFIBOOT" "${DISK}p2"
mkfs.btrfs -L "ROOT" "${DISK}p3" -f
mount -t btrfs "${DISK}p3" /mnt
else
mkfs.vfat -F32 -n "EFIBOOT" "${DISK}2"
mkfs.btrfs -L "ROOT" "${DISK}3" -f
mount -t btrfs "${DISK}3" /mnt
fi
ls /mnt | xargs btrfs subvolume delete
btrfs subvolume create /mnt/@
umount /mnt
;;
*)
echo "Error, rebooting in 3" && sleep 1
echo "Error, rebooting in 2" && sleep 1
echo "Error, rebooting in 1" && sleep 1
reboot now
;;
esac

mount -t btrfs -o subvol=@ -L ROOT /mnt
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

if ! grep -qs '/mnt' /proc/mounts; then
    echo "ERROR #DN4G7, drive is not mounted"
    echo "Error, rebooting in 3" && sleep 1
    echo "Error, rebooting in 2" && sleep 1
    echo "Error, rebooting in 1" && sleep 1
    reboot now
fi

echo "---------------------------"
echo "Installing OS on main drive"
echo "---------------------------"
pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed
genfstab -U /mnt >> /mnt/etc/fstab
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt/root/asrsrv
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
echo "--------"
echo "Checking"
echo "--------"
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -lt 8000000 ]]; then
    mkdir /mnt/opt/swap
    chattr +C /mnt/opt/swap
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab
fi
echo "----------------------------"
echo "System ready for #WEZKGOXILW"
echo "----------------------------"
