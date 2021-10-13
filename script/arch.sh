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

cryptsetup open /dev/sda1 lvm

pvcreate /dev/mapper/lvm
vgcreate matrix /dev/mapper/lvm
lvcreate -l +100%FREE matrix -n rootvol

# Formatting the partitions
mkfs.ext4 /dev/mapper/matrix-rootvol

# Mount partition
mount /dev/matrix/rootvol /mnt/

pacstrap /mnt linux-lts base base-devel lvm2 grub

arch-chroot /mnt

packagelist=(
  # Xorg
  xorg-server xorg-xinit xorg-xev xorg-xprop xorg-xsetroot xorg-xkill xsel xclip xcalib
  # Intel
  mesa libva-utils intel-ucode
  # Window manager
  bspwm sxhkd rofi thunar xdg-user-dirs slock
  # Laptop
  acpi acpid tlp powertop lm_sensors libimobiledevice xf86-input-libinput 
  # Coreboot
  flashrom
  # sound, bluetooth, vpn
  pipewire pipewire-alsa pipewire-pulse pavucontrol bluez bluez-utils blueberry
  # Coding  
  python-pip git gvim
  # Office programs
  libreoffice-still texlive-most zathura zathura-pdf-mupdf
  # Terminal tools 
  pacman-contrib htop openssh man-db gpm wget curl playerctl
  # Multimedia
  firefox sxiv scrot youtube-dl mpv telegram-desktop discord 
  # Look and feel
  zsh lxappearance feh neofetch ttf-dejavu ttf-font-awesome
  # Security
  cryptsetup
  # Network
  dhcpcd iwd reflector
)

pacman -Syu ${packagelist[@]}

# edit fstab 
cat << EOF > /etc/fstab
/dev/mapper/matrix-rootvol / ext4 noatime 0 1
EOF

# Create user
useradd -G wheel -m -d /home/user user
passwd user
useradd -G wheel -m -d /home/help help
passwd help

chsh -s /bin/zsh user

# Add sudo privileges
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Set the time zone and a system clock
ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc --utc

# Set default locale
echo -e "en_US.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8" >> /etc/locale.gen

# Update current locale
locale-gen

# Set system language
echo LANG=en_US.UTF-8 > /etc/locale.conf

# Set keymap and font for console 
echo -e "KEYMAP=ru\nFONT=cyr-sun16" > /etc/vconsole.conf

# Set the hostname
echo arch > /etc/hostname

# Set the host
cat << EOF > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    arch.localdomain arch
EOF

su user 
git clone https://aur.archlinux.org/yay.git $HOME/git/yay
cd $HOME/git/yay && makepkg -si

packagelist=(
  # Window manager
  rxvt-unicode-truecolor-wide-glyphs lf-bin alternating-layouts-git
  # Network
  iwgtk
  # Coreboot
  coreboot-utils
  # Thinkpad
  libva-intel-driver-g45-h264
  # Multimedia
  spotify
)

yay -Syu ${packagelist[@]}

git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $HOME/.zsh/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting $HOME/.zsh/zsh-syntax-highlighting
git clone --depth=1 https://github.com/woefe/git-prompt.zsh $HOME/.zsh/git-prompt

exit

systemctl enable tlp iwd gpm dhcpcd bluetooth slock@user.service

# Don't enter a password twice
mkdir /root/secrets && chmod 700 /root/secrets
head -c 64 /dev/urandom > /root/secrets/crypto_keyfile.bin && chmod 600 /root/secrets/crypto_keyfile.bin
cryptsetup -v luksAddKey -i 1 /dev/sda1 /root/secrets/crypto_keyfile.bin

# Create grub configuration
blkid 
cat << EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR="Arch"
GRUB_CMDLINE_LINUX="iomem=relaxed cryptdevice=UUID=3014c533-4361-4358-8a97-fe6474733224:cryptlvm cryptkey=rootfs:/root/secrets/crypto_keyfile.bin"
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3"
EOF

# Configure mkinitcpio
sed -i "s|^FILES=.*|FILES=(/root/secrets/crypto_keyfile.bin)|" /etc/mkinitcpio.conf
sed -i "s|^HOOKS=.*|HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)|" /etc/mkinitcpio.conf

# Regenerate initrd image
mkinitcpio -p linux-lts

# Install grub and create configuration
mkdir /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Exit new system and go into the cd shell
exit

# Reboot into the new system, don't forget to remove the usb
reboot
