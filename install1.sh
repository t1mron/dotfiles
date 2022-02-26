export DRIVE="nvme0n1"
export EXT4_OPTS="rw,noatime,discard"
export FAT32_OPTS="defaults,noatime"

# Sync time 
timedatectl set-ntp true

# Delete a luks cont. if exist
head -c 3145728 /dev/urandom > /dev/$DRIVE; sync

# gpt
(echo g;echo w) | fdisk /dev/$DRIVE

# 512MB - EFI
(echo n;echo ;echo ;echo 1050623;echo w) | fdisk /dev/$DRIVE

# All
(echo n;echo ;echo ;echo ;echo w) | fdisk /dev/$DRIVE

# Encrypt and open
cryptsetup luksFormat --type luks1 /dev/${DRIVE}p2
cryptsetup open /dev/${DRIVE}p2 crypt

# lvm2
pvcreate /dev/mapper/crypt
vgcreate linux /dev/mapper/crypt
lvcreate -L 25G linux -n arch
lvcreate -L 16G linux -n swap
lvcreate -l +100%FREE linux -n home

# Formatting the partitions
mkfs.fat -F32 /dev/${DRIVE}p1
mkfs.ext4 /dev/mapper/linux-arch
mkfs.ext4 /dev/mapper/linux-home
mkswap /dev/mapper/linux-swap

# Mount partition
mount -o $EXT4_OPTS /dev/mapper/linux-arch /mnt/
mkdir -p /mnt/boot/efi
mkdir -p /mnt/home
mount -o $FAT32_OPTS /dev/${DRIVE}p1 /mnt/boot/efi
mount -o $EXT4_OPTS /dev/mapper/linux-home /mnt/home

pacstrap /mnt linux-lts base base-devel lvm2 grub amd-ucode

git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles
cp -r $HOME/git/dotfiles/etc /mnt/
rm -rf $HOME/git

DRIVE=$DRIVE FAT32_OPTS=$FAT32_OPTS EXT4_OPTS=$EXT4_OPTS PS1='(chroot) # ' arch-chroot /mnt

packagelist=(
  # amd
  mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver libva-utils
  # XDG
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-user-dirs xdg-user-dirs-gtk xdg-utils
  # Window manager 
  sway swaylock swayidle wofi foot thunar lf wl-clipboard lxappearance neofetch
  # Thunar
  gvfs udiskie file-roller thunar-archive-plugin tumbler
  # Laptop
  tlp brightnessctl
  # sound, bluetooth, vpn
  pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack bluez bluez-utils blueberry pavucontrol
  # Coding  
  python-pip git neovim code
  # Office programs
  libreoffice-still okular zathura-pdf-mupdf nomacs imv
  # Terminal tools 
  htop gpm jq openssh man-db
  # fonts
  ttf-hack ttf-font-awesome ttf-dejavu
  # Multimedia
  mpv playerctl yt-dlp telegram-desktop qbittorrent grim slurp torbrowser-launcher
  # IOS
  libimobiledevice
  # Security
  cryptsetup ufw bitwarden
  # Network
  iwd wget curl tor wireguard-tools reflector
  # Virtualization
)

# Create user
useradd -G wheel,rfkill -m -d /home/user user
passwd user
useradd -G wheel -m -d /home/help help
passwd help

# Set the time zone and a system clock
ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc --utc

# Update current locale
locale-gen

su user 
git clone https://aur.archlinux.org/yay.git $HOME/git/yay
cd $HOME/git/yay && makepkg -si

yay -Syu wev lf mpv-mpris iwgtk librewolf-bin

git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles

ln -sf $HOME/git/dotfiles/{.config,.fonts,.inputrc,.gtkrc-2.0,.vimrc,.bash_profile,.bashrc} ~/

# python scripts
pip install --user swaytools Jupyter numpy

exit

systemctl enable tlp iwd gpm bluetooth systemd-networkd systemd-resolved

# Don't enter a password twice
dd bs=512 count=4 if=/dev/urandom of=/boot/volume.key
cryptsetup -v luksAddKey -i 1 /dev/${DRIVE}p2 /boot/volume.key
chmod 000 /boot/volume.key
chmod -R g-rwx,o-rwx /boot

export UEFI_UUID=$(blkid -s UUID -o value /dev/${DRIVE}p1)
export LUKS_UUID=$(blkid -s UUID -o value /dev/${DRIVE}p2)
export ROOT_UUID=$(blkid -s UUID -o value /dev/mapper/linux-arch)
export HOME_UUID=$(blkid -s UUID -o value /dev/mapper/linux-home)
export SWAP_UUID=$(blkid -s UUID -o value /dev/mapper/linux-swap)

echo "linux UUID=$LUKS_UUID /boot/volume.key luks" > /etc/crypttab

# lvm trim support
sed -i 's/issue_discards = 0/issue_discards = 1/' /etc/lvm/lvm.conf

cat << EOF > /etc/fstab
UUID=$ROOT_UUID / ext4 $EXT4_OPTS 0 1
UUID=$HOME_UUID /home ext4 $EXT4_OPTS 0 2
UUID=$UEFI_UUID /boot/efi vfat $FAT32_OPTS 0 2
UUID=$SWAP_UUID none swap defaults 0 1
EOF

# Grub configuration
cat << EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR="Arch"
GRUB_ENABLE_CRYPTODISK=y
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 resume=UUID=$SWAP_UUID"
GRUB_CMDLINE_LINUX="net.ifnames=0 zswap.enabled=1 rd.luks.options=discard rd.lvm.vg=linux rd.luks.uuid=$LUKS_UUID"
EOF

# Install grub and create configuration
mkdir -p /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=x86_64-efi --boot-directory=/boot --efi-directory=/boot/efi --bootloader-id=BOOT --recheck

# Regenerate initrd image
mkinitcpio -p linux-lts

# Exit new system and go into the cd shell
exit 

# Reboot into the new system, don't forget to remove the usb
reboot
