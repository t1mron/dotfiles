sudo apt install ssh debootstrap

# Wipe disk before install
(echo g;echo w) | fdisk /dev/sda

# /dev/sda1 All Linux filesystem
(echo n;echo ;echo ;echo ; echo w) | fdisk /dev/sda

# Formatting the partitions
mkfs.ext4 -L root /dev/sda1

# Mount partition
mount /dev/sda1 /mnt

# Install base system
debootstrap --variant=minbase --arch amd64 ceres /mnt http://deb.devuan.org/merged/ 

# Chroot into installed system
mount -t proc /proc /mnt/proc/
mount -t sysfs /sys /mnt/sys/
mount -o bind /dev /mnt/dev/
mount -o pts /dev/pts /mnt/dev/pts/

chroot /mnt /bin/bash


# Edit fstab
cat << EOF > /etc/fstab
# <file system>        <dir>         <type>    <options>             <dump> <pass>
/dev/sda1              /             ext4      rw,noatime              1      1
EOF

# Create user
useradd -G sudo -m -d /home/user user
passwd user
useradd -G sudo -m -d /home/help help
passwd help

# Set the time zone and a system clock
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc --utc

# Set default locale
echo -e "en_US.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8" >> /etc/locale.gen

# Update current locale
locale-gen

# Set system language
echo LANG=en_US.UTF-8 >> /etc/locale.conf

# Set keymap and font for console 
echo -e "KEYMAP=ru\nFONT=cyr-sun16" >> /etc/vconsole.conf

# Set the hostname
echo arch >> /etc/hostname

# Set the host
cat << EOF | tee -a /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    arch.localdomain arch
EOF






# Setup grub
sed -i "s|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=1|" /etc/default/grub
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT='loglevel=3 quiet acpi_backlight=vendor'|" /etc/default/grub
sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX='cryptdevice=/dev/nvme0n1p3:archlinux'|" /etc/default/grub

# Configure mkinitcpio
sed -i "s|^MODULES=.*|MODULES=(amdgpu)|" /etc/mkinitcpio.conf
sed -i "s|^HOOKS=.*|HOOKS=(base udev autodetect keyboard modconf block encrypt lvm2 filesystems fsck)|" /etc/mkinitcpio.conf

# Regenerate initrd image
mkinitcpio -p linux

# Install grub and create configuration
grub-install --boot-directory=/boot --efi-directory=/boot/efi /dev/nvme0n1p2
grub-mkconfig -o /boot/grub/grub.cfg
grub-mkconfig -o /boot/efi/EFI/arch/grub.cfg





# Exit new system and go into the cd shell
exit

# Reboot into the new system, don't forget to remove the usb
reboot

sudo pacman -Syu

# Install AUR helper - yay
git clone https://aur.archlinux.org/yay.git /home/user/git/yay
cd /home/user/git/yay && makepkg -si

# Clone my repo
git clone https://github.com/t1mron/dotfiles_arch.git /home/user/git/dotfiles_arch
cd /home/user/git/dotfiles_arch && sudo cp -r etc / && cp /user/. /home/user/




# migrate from stable to sid
apt install ssh sudo 

cat << EOF > /etc/apt/sources.list
deb     http://deb.devuan.org/merged ceres main
deb-src http://deb.devuan.org/merged ceres main
EOF

apt-get update && apt-get upgrade && apt-get dist-upgrade && apt-get autoremove && reboot
apt install linux-image-5.10.0-7-amd64

# basic 
apt install sysv-rc-conf network-manager iwd wget curl vim git

# Window manager
apt install bspwm sxhkd xserver-xorg-core xinit xinput x11-utils x11-xserver-utils rxvt-unicode polybar suckless-tools ranger rofi fonts-font-awesome fonts-hack arandr autorandr

# Laptop (soon)

# wi-fi, sound, bluetooth, vpn (soon)

# Office programs
apt install texlive-latex-recommended zathura

# vim plugins
apt install python3-pip
pip3 install pynvim pylint

# Look and feel
apt install neofetch zsh zsh-antigen

# Utilities
apt install man-db flameshot redshift mpv sxiv

# System tools 
apt install htop 

# Multimedia
apt install firefox-esr telegram-desktop 

# Virtualisation (soon)

# Security 
apt install ufw 
ufw enable 

# Create user
useradd -G sudo -m -d /home/user user
passwd user
useradd -G sudo -m -d /home/help help
passwd help

# dotfiles
git clone --depth=1 https://github.com/t1mron/dotfiles_devuan $HOME/git/dotfiles_devuan
cp -r $HOME/git/dotfiles_devuan/. $HOME/ && rm -rf $HOME/root .git LICENSE README.md readme.txt
sudo cp -r $HOME/git/dotfiles_devuan/root/. /

git clone https://github.com/alexanderjeurissen/ranger_devicons $HOME/.config/ranger/plugins/ranger_devicons

PlugInstall
CocInstall coc-vimlsp coc-python coc-sh coc-vimtex coc-explorer
