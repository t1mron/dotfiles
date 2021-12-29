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

pacstrap /mnt linux-lts base base-devel lvm2 grub

arch-chroot /mnt

packagelist=(
  # Xorg
  xorg-server xorg-xinit xorg-xev xorg-xprop xorg-xsetroot xorg-xkill xsel xclip xcalib
  # Intel
  mesa libva-utils intel-ucode xf86-video-intel
  # Window manager 
  bspwm sxhkd rofi thunar xdg-user-dirs
  # Laptop
  acpi acpid tlp powertop lm_sensors xf86-input-libinput 
  # Coreboot
  flashrom
  # sound, bluetooth, vpn
  pipewire pipewire-alsa pipewire-pulse pavucontrol bluez bluez-utils blueberry
  # Coding  
  python-pip git gvim
  # Office programs
  okular
  # Terminal tools 
  pacman-contrib htop openssh man-db gpm wget curl playerctl
  # Multimedia
  firefox mpv telegram-desktop discord 
  # Look and feel
  zsh lxappearance feh neofetch ttf-dejavu ttf-font-awesome
  # Security
  cryptsetup
  # Network
  iwd reflector
)

pacman -Syu ${packagelist[@]}

# edit fstab 
cat << EOF > /etc/fstab
/dev/mapper/vg1-root / ext4 defaults,noatime 0 0
EOF

# Create user
useradd -G wheel,rfkill -m -d /home/user user
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

cat << EOF > /etc/systemd/network/20-all.network
[Match]
Name=e*

[Network]
DHCP=yes
EOF

su user 
git clone https://aur.archlinux.org/yay.git $HOME/git/yay
cd $HOME/git/yay && makepkg -si

packagelist=(
  # Window manager
  polybar
  # Network
  iwgtk
  # Coreboot
  coreboot-utils
  # Thinkpad
  libva-intel-driver-g45-h264
)

yay -Syu ${packagelist[@]}

git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $HOME/.zsh/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting $HOME/.zsh/zsh-syntax-highlighting
git clone --depth=1 https://github.com/woefe/git-prompt.zsh $HOME/.zsh/git-prompt

exit

systemctl enable tlp iwd gpm bluetooth systemd-networkd systemd-resolved

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
GRUB_CMDLINE_LINUX="iomem=relaxed cryptdevice=UUID=49891c4f-649e-4601-a0cc-6bb5b571617d:cryptlvm cryptkey=rootfs:/root/secrets/crypto_keyfile.bin"
GRUB_CMDLINE_LINUX_DEFAULT=""
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
