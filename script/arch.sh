# Sync time 
timedatectl set-ntp true 

# Delete a luks cont. if exist
head -c 3145728 /dev/urandom > /dev/sda; sync

# mbr
(echo o;echo w) | fdisk /dev/sda

# /dev/sda1 All Linux filesystem
(echo n;echo ;echo ;echo ;echo ;echo a;echo w) | fdisk /dev/sda

# Load encrypt modules
modprobe dm-mod

# Encrypt and open /dev/sda1
cryptsetup -v --cipher serpent-xts-plain64 --key-size 512 --hash whirlpool --use-random --verify-passphrase luksFormat --type luks1 /dev/sda1

cryptsetup open /dev/sda1 sda1_crypt

pvcreate /dev/mapper/sda1_crypt
vgcreate vg1 /dev/mapper/sda1_crypt
lvcreate -l +100%FREE vg1 -n root 

# Formatting the partitions
mkfs.ext4 /dev/mapper/vg1-root

# Mount partition
mount /dev/mapper/vg1-root /mnt/

pacstrap /mnt linux-lts linux-lts-headers base base-devel lvm2 grub

git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles
cp -r $HOME/git/dotfiles/root/arch/. /mnt/

arch-chroot /mnt

packagelist=(
  # Xorg
  xorg-server xorg-xinit xorg-xrandr xorg-xev xorg-xprop xorg-xsetroot xorg-xkill xterm xsel xclip xcalib
  # Intel
  mesa lib32-mesa xf86-video-intel libva-utils 
  # Window manager 
  bspwm sxhkd rofi thunar jgmenu slock xdg-user-dirs
  # Thunar
  gvfs file-roller thunar-archive-plugin tumbler udisks2
  # Laptop
  acpi acpid tlp powertop lm_sensors xf86-input-libinput 
  # Coreboot
  flashrom
  # sound, bluetooth, vpn
  pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack pavucontrol bluez bluez-utils blueberry
  # Coding  
  python-pip git gvim vi 
  # Office programs
  okular nomacs
  # Terminal tools 
  pacman-contrib htop openssh man-db gpm wget curl playerctl zram-generator mlocate
  # Multimedia
  firefox mpv telegram-desktop discord qbittorrent flameshot gimp
  # Look and feel
  zsh lxappearance feh neofetch ttf-dejavu ttf-font-awesome 
  # Security
  cryptsetup
  # Network
  iwd reflector
  # Virtualization
  docker docker-compose virtualbox virtualbox-host-dkms
)

pacman -Syu ${packagelist[@]}

# Create user
useradd -G wheel,rfkill,docker,vboxusers -m -d /home/user user
passwd user
useradd -G wheel -m -d /home/help help
passwd help

chsh -s /bin/zsh user

# Set the time zone and a system clock
ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc --utc

# Update current locale
locale-gen

# hibernation
dd if=/dev/zero of=/swapfile bs=1M count=4096
mkswap /swapfile
chmod 600 /swapfile
swapon /swapfile
#echo "vm.swappiness=100" > /etc/sysctl.d/99-swappiness.conf

su user 
git clone https://aur.archlinux.org/yay.git $HOME/git/yay
cd $HOME/git/yay && makepkg -si

yay -Syu polybar iwgtk coreboot-utils libva-intel-driver-g45-h264 onlyoffice-bin

git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $HOME/.zsh/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting $HOME/.zsh/zsh-syntax-highlighting
git clone --depth=1 https://github.com/woefe/git-prompt.zsh $HOME/.zsh/git-prompt

git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles
cp -r $HOME/git/dotfiles/user/arch/. ~/

exit

systemctl enable tlp iwd gpm bluetooth systemd-networkd systemd-resolved docker reflector

# Don't enter a password twice
mkdir /root/secrets && chmod 700 /root/secrets
head -c 64 /dev/urandom > /root/secrets/crypto_keyfile.bin && chmod 600 /root/secrets/crypto_keyfile.bin
cryptsetup -v luksAddKey -i 1 /dev/sda1 /root/secrets/crypto_keyfile.bin

# filefrag -v /swapfile
# Create grub configuration
cat << EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR="Arch"
GRUB_CMDLINE_LINUX="iomem=relaxed tsc=unstable cryptdevice=UUID=$(blkid -s UUID -o value /dev/sda1):sda1_crypt cryptkey=rootfs:/root/secrets/crypto_keyfile.bin"
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 resume=/dev/mapper/vg1-root resume_offset=30152704 zswap.enabled=0"
EOF

# Regenerate initrd image
mkinitcpio -p linux-lts

# Install grub and create configuration
mkdir /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Exit new system and go into the cd shell
exit 

# Reboot into the new system, don't forget to remove the usb
reboot
