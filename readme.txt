sudo apt install ssh debootstrap arch-install-scripts

# Wipe disk before install
(echo o;echo w) | fdisk /dev/sda

# /dev/sda1 All Linux filesystem
(echo n;echo ;echo ;echo ;echo ;echo a;echo w) | fdisk /dev/sda

# Formatting the partitions
mkfs.ext4 -L root /dev/sda1

# Mount partition
mount /dev/sda1 /mnt

# Install base system
debootstrap --variant=minbase --include=locales --arch amd64 ceres /mnt http://deb.devuan.org/merged/ 

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Enter the new system
arch-chroot /mnt /bin/bash

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

# Set the host
cat << EOF > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    devuan.localdomain devuan
EOF

# basic
apt install linux-image-5.10.0-7-amd64 grub2 sudo sysv-rc-conf network-manager iwd ssh neovim

# remove modemmanager
sudo apt-get purge modemmanager

# clean apt downloaded archives
apt clean

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

packagelist=(
  # Window manager
  bspwm sxhkd xserver-xorg-core xinit xinput x11-utils x11-xserver-utils rxvt-unicode polybar suckless-tools ranger rofi fonts-font-awesome fonts-hack arandr
  # Laptop (soon)
  # wi-fi, sound, bluetooth, vpn (soon)
  # Office programs
  texlive-latex-recommended zathura
  # Coding
  python3-pip git
  # Look and feel
  neofetch zsh zsh-antigen
  # Utilities
  man-db redshift 
  # System tools 
  htop wget curl ping
  # Multimedia
  telegram-desktop flameshot mpv sxiv
  # Virtualisation (soon)
  # Security 
  ufw 
)

apt install ${packagelist[@]}
pip3 install pynvim pylint


# dotfiles
git clone --depth=1 https://github.com/t1mron/dotfiles_devuan $HOME/git/dotfiles_devuan
cp -r $HOME/git/dotfiles_devuan/. $HOME/ && rm -rf $HOME/root .git LICENSE README.md readme.txt
sudo cp -r $HOME/git/dotfiles_devuan/root/. /

git clone https://github.com/alexanderjeurissen/ranger_devicons $HOME/.config/ranger/plugins/ranger_devicons


:PlugInstall
:CocInstall coc-vimlsp coc-python coc-sh coc-vimtex coc-explorer
