# Wipe disk before install
dd if=/dev/zero of=/dev/sda bs=446 count=1; sync
dd if=/dev/urandom of=/dev/sda bs=2M; sync

head -c 3145728 /dev/urandom > /dev/sda; sync 
(echo o;echo w) | sudo fdisk /dev/sda

# /dev/sda1 All Linux filesystem
(echo n;echo ;echo ;echo ;echo ;echo a;echo w) | sudo fdisk /dev/sda

# Load encrypt modules
sudo modprobe dm-mod

# Encrypt and open /dev/sda1
sudo cryptsetup -v --cipher serpent-xts-plain64 --key-size 512 --hash whirlpool --use-random --verify-passphrase luksFormat --type luks1 /dev/sda1

sudo cryptsetup open /dev/sda1 lvm

sudo pvcreate /dev/mapper/lvm
sudo vgcreate matrix /dev/mapper/lvm
sudo lvcreate -l +100%FREE matrix -n rootvol

# Formatting the partitions
sudo mkfs.ext4 /dev/mapper/matrix-rootvol

# Mount partition
sudo mount /dev/matrix/rootvol /mnt/

# Install base system
debootstrap --variant=minbase --arch amd64 ceres /mnt/ http://deb.devuan.org/merged/ 

# mount partitions for chroot
mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/dev

# chroot
chroot /mnt/ /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"

# edit fstab 
cat << EOF > /etc/fstab
/dev/mapper/matrix-rootvol / ext4 noatime 0 1
EOF

# install packages
apt update

packagelist=(
  # basic
  linux-image-amd64 lvm2 sysv-rc-conf zram-tools
  # Window manager
  bspwm sxhkd xserver-xorg-core xserver-xorg-input-evdev xinit xinput x11-utils x11-xserver-utils xterm lemonbar nnn suckless-tools rofi spacefm-gtk3
  # Laptop (soon)
  tlp powertop lm-sensors thinkfan
  # wi-fi, sound, bluetooth, vpn (soon)
  alsa-utils apulse
  # Office programs
  libreoffice libreoffice-gtk3 texlive-latex-recommended latexmk chktex zathura
  # Terminal tools 
  git wget curl man-db htop iputils-ping iproute2
  # Locale
  locales
  # Multimedia
  firefox telegram-desktop mpv scrot sxiv youtube-dl 
  # Coding
  git python3-pip
  # Look and feel
  neofetch zsh
  # Utilities
  # Network
  dhcpcd5 iwd wireless-tools bc
  # Security 
  sudo
  # Firmware
  mesa-utils vainfo
  # Neovim from source
  autoconf automake cmake g++ gettext libncurses5-dev libtool libtool-bin libunibilium-dev libunibilium4 ninja-build pkg-config software-properties-common unzip
)

DEBIAN_FRONTEND=noninteractive apt --no-install-recommends --assume-yes install ${packagelist[@]}

apt install ${packagelist[@]}

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

git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $HOME/.zsh/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting $HOME/.zsh/zsh-syntax-highlighting
git clone --depth=1 https://github.com/woefe/git-prompt.zsh $HOME/.zsh/git-prompt

git clone --depth=1 https://github.com/t1mron/dotfiles_devuan $HOME/git/dotfiles_devuan
cp -r $HOME/git/dotfiles_devuan/. $HOME/ && rm -rf $HOME/{root,.git,LICENSE,README.md,readme.txt}
sudo cp -r $HOME/git/dotfiles_devuan/root/. /
fc-cache -fv

git clone --depth=1 --single-branch --branch release-0.5 https://github.com/neovim/neovim
make CMAKE_BUILD_TYPE=Release
sudo make install

sudo rm -rf /etc/fonts/conf.d/70-no-bitmaps.conf    (????)

exit

update-rc.d zram defaults
update-rc.d zram enable

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

