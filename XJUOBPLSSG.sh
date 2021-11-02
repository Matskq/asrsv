#!/bin/bash
echo -e "\nJust a final touch here and there"
echo "---------"
echo "Scrubbing"
echo "---------"
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/boot ${DISK}
else
    grub-install --efi-directory=/boot ${DISK}
fi
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\nEnabling some services"

ntpd -qg
systemctl disable dhcpcd.service
systemctl stop dhcpcd.service
systemctl enable NetworkManager.service
systemctl enable bluetooth
echo "Doing something"
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

cd $pwd
echo "We are done here, shutdown and eject media"
