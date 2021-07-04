sudo apt install ssh debootstrap arch-install-scripts

# Wipe disk before install
head -c 3145728 /dev/urandom > /dev/sda; sync 
(echo o;echo w) | sudo fdisk /dev/sda

# /dev/sda1 All Linux filesystem
(echo n;echo ;echo ;echo ;echo ;echo a;echo w) | sudo fdisk /dev/sda

# Formatting the partitions
sudo mkfs.ext4 /dev/sda1

# Mount partition
mount /dev/sda1 /mnt

# Install base system
sudo debootstrap --variant=minbase --arch amd64 ceres /mnt http://deb.devuan.org/merged/ 

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# sources list
cat << EOF > /mnt/etc/apt/sources.list 
deb http://deb.devuan.org/merged ceres main 
deb http://deb.devuan.org/merged beowulf main non-free contrib
EOF

# Enter the new system
arch-chroot /mnt /bin/bash

packagelist=(
  # basic
  linux-image-amd64 grub2 cryptsetup lvm2 sysv-rc-conf
  # Window manager
  bspwm sxhkd xserver-xorg-core xinit xinput x11-utils x11-xserver-utils xterm polybar ranger suckless-tools rofi thunar
  # Laptop (soon)
  tlp powertop acpi lm-sensors thinkfan
  # wi-fi, sound, bluetooth, vpn (soon)
  iwd openresolv wireless-tools bc 
  # Office programs
  texlive-latex-recommended zathura
  # Terminal tools 
  git wget man-db htop iputils-ping iproute2
  # Fonts
  fonts-font-awesome
  # Locale
  locales
  # Multimedia
  telegram-desktop flameshot mpv sxiv
  # Coding
  neovim git python3-pip nodejs npm
  # Look and feel
  neofetch zsh exa
  # Utilities
  redshift 
  # Security 
  sudo ufw 
  # Firmware
  firmware-iwlwifi
)

DEBIAN_FRONTEND=noninteractive apt --assume-yes install ${packagelist[@]}

apt install ${packagelist[@]}
#pip3 install pynvim

# clean apt downloaded archives
apt clean

# Create user
useradd -G sudo -m -d /home/user user
passwd user
useradd -G sudo -m -d /home/help help
passwd help

# default shell zsh
chsh -s /bin/zsh user
chsh -s /bin/bash help

# Set the time zone and a system clock
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc --utc

# Set default locale
echo -e "en_US.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8" >> /etc/locale.gen

# Update current locale
locale-gen

# Set the host
cat << EOF > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    devuan.localdomain devuan
EOF

# dotfiles
su user
git clone --depth=1 https://github.com/t1mron/dotfiles_devuan $HOME/git/dotfiles_devuan
cp -r $HOME/git/dotfiles_devuan/. $HOME/ && rm -rf $HOME/{root,.git,LICENSE,README.md,readme.txt}
sudo cp -r $HOME/git/dotfiles_devuan/root/. /

exit

# Setup grub
sed -i "s|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=1|" /etc/default/grub

# Install grub and create configuration
grub-install --root-directory=/ --boot-directory=/boot /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# exit the chroot environmen
exit

# Reboot into the new system, don't forget to remove the usb
reboot

-------------------------------------------------------------------------

sudo sensors-detect

:PlugInstall
:CocInstall coc-explorer
