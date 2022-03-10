export DRIVE="nvme0n1"
export EXT4_OPTS="rw,noatime,discard"
export FAT32_OPTS="defaults,noatime"

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
vgcreate main /dev/mapper/crypt
lvcreate -L 25G main -n linux_void
lvcreate -L 15G main -n andoid
lvcreate -L 8G main -n linux_swap
lvcreate -l +100%FREE main -n linux_home

# Formatting the partitions
mkfs.fat -F32 /dev/${DRIVE}p1
mkfs.ext4 /dev/mapper/main-linux_void
mkfs.ext4 /dev/mapper/main-android
mkfs.ext4 /dev/mapper/main-linux_home
mkswap /dev/mapper/main-linux_swap
swapon /dev/mapper/main-linux_swap

# Mount partition
mount -o $EXT4_OPTS /dev/mapper/main-linux_void /mnt/
mkdir -p /mnt/boot/efi
mkdir -p /mnt/home
mount -o $FAT32_OPTS /dev/${DRIVE}p1 /mnt/boot/efi
mount -o $EXT4_OPTS /dev/mapper/main-linux_home /mnt/home

# changing repository mirror
mkdir -p /etc/xbps.d
cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/
#sed -i 's|https://alpha.de.repo.voidlinux.org|http://lysator7eknrfl47rlyxvgeamrv7ucefgrrlhk7rouv3sna25asetwid.onion/pub/voidlinux|g' /etc/xbps.d/*-repository-*.conf
sed -i 's|https://alpha.de.repo.voidlinux.org|https://mirror.yandex.ru/mirrors/voidlinux|g' /etc/xbps.d/*-repository-*.conf

xbps-install -Syu -R https://alpha.de.repo.voidlinux.org/current -r /mnt linux-lts base-system dbus-elogind dbus-elogind-libs elogind polkit rtkit grub-x86_64-efi lvm2 socklog-void chrony

for dir in dev proc sys run; do mount --rbind /$dir /mnt/$dir; mount --make-rslave /mnt/$dir; done

cp /etc/resolv.conf /mnt/etc/

DRIVE=$DRIVE FAT32_OPTS=$FAT32_OPTS EXT4_OPTS=$EXT4_OPTS PS1='(chroot) # ' chroot /mnt/ /bin/bash
chown root:root /
chmod 755 /

# changing repository mirror
mkdir -p /etc/xbps.d
cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/
#sed -i 's|https://alpha.de.repo.voidlinux.org|http://lysator7eknrfl47rlyxvgeamrv7ucefgrrlhk7rouv3sna25asetwid.onion/pub/voidlinux|g' /etc/xbps.d/*-repository-*.conf
sed -i 's|https://alpha.de.repo.voidlinux.org|https://mirror.yandex.ru/mirrors/voidlinux|g' /etc/xbps.d/*-repository-*.conf

cat << EOF > /etc/xbps.d/10-ignore.conf
ignorepkg=sudo
ignorepkg=wpa_supplicant
ignorepkg=void-artwork
EOF

xbps-remove sudo wpa_supplicant void-artwork
xbps-install -Syu void-repo-multilib

packagelist=(
  # amd
  mesa-dri vulkan-loader mesa-vulkan-radeon mesa-vaapi mesa-vdpau libva-utils
  # intel
  intel-video-accel mesa-vulkan-intel
  # XDG
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-user-dirs xdg-user-dirs-gtk xdg-utils
  # WM
  sway swaylock swayidle wofi foot wev Thunar lf wl-clipboard lxappearance neofetch
  # Thunar
  gvfs udiskie file-roller thunar-archive-plugin tumbler
  # Laptop
  tlp brightnessctl
  # sound, bluetooth, vpn
  pipewire libspa-bluetooth bluez blueman pulseaudio-utils pavucontrol
  # Coding  
  go python3-pip git neovim vscode
  # Office programs
  libreoffice okular zathura-pdf-mupdf nomacs imv
  # Terminal tools 
  htop gpm jq vsv vpm bsdtar
  # fonts
  font-hack-ttf font-awesome5 dejavu-fonts-ttf
  # Multimedia
  mpv mpv-mpris playerctl yt-dlp telegram-desktop qbittorrent grim slurp gimp kdenlive
  # IOS
  usbmuxd libimobiledevice
  # Security
  cryptsetup opendoas ufw
  # Network
  iwd openresolv iwgtk wget curl tor proxychains-ng wireguard
  # Virtualization
  docker docker-compose flatpak virt-manager libvirt qemu bridge-utils
)

xbps-install -Syu ${packagelist[@]}

# symlinks
mkdir -p /etc/mpv/scripts/
ln -sf /usr/lib/mpv-mpris/mpris.so /etc/mpv/scripts/
ln -sf /bin/doas /bin/sudo
ln -sf /bin/code-oss /bin/code

git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles
cp -r $HOME/git/dotfiles/etc /
rm -rf $HOME/git

# create user
useradd -G wheel,socklog,storage,video,audio,input,bluetooth,docker,kvm,libvirt -m -d /home/user user
passwd user
useradd -G wheel,storage -m -d /home/help help
passwd help

chsh -s /bin/bash root

# user workflow
su user 
git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles

ln -sf $HOME/git/dotfiles/{.config,.fonts,.inputrc,.gtkrc-2.0,.vimrc,.bash_profile,.bashrc} ~/

# python scripts
pip install --user swaytools Jupyter numpy neovim

exit

# set the time zone
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

# Don't enter a password twice
dd bs=512 count=4 if=/dev/urandom of=/boot/volume.key
cryptsetup -v luksAddKey -i 1 /dev/${DRIVE}p2 /boot/volume.key
chmod 000 /boot/volume.key
chmod -R g-rwx,o-rwx /boot

# disable tlp suspend for bluetooth/wifi
#lspci -knn | grep Net -A2; lsusb
echo USB_DENYLIST="8086:2723" >> /etc/tlp.conf

export UEFI_UUID=$(blkid -s UUID -o value /dev/${DRIVE}p1)
export LUKS_UUID=$(blkid -s UUID -o value /dev/${DRIVE}p2)
export ROOT_UUID=$(blkid -s UUID -o value /dev/mapper/main-linux_void)
export HOME_UUID=$(blkid -s UUID -o value /dev/mapper/main-linux_home)
export SWAP_UUID=$(blkid -s UUID -o value /dev/mapper/main-linux_swap)

echo "main UUID=$LUKS_UUID /boot/volume.key luks" > /etc/crypttab

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
GRUB_DISTRIBUTOR="Void"
GRUB_ENABLE_CRYPTODISK=y
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 resume=UUID=$SWAP_UUID"
GRUB_CMDLINE_LINUX="net.ifnames=0 zswap.enabled=1 rd.luks.options=discard rd.lvm.vg=main rd.luks.uuid=$LUKS_UUID"
EOF

# Install grub and create configuration
mkdir -p /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=x86_64-efi --boot-directory=/boot --efi-directory=/boot/efi --bootloader-id=BOOT --recheck

# enable services
ufw enable
ln -s /etc/sv/{dbus,polkitd,socklog-unix,nanoklogd,chronyd,gpm,iwd,dhcpcd,bluetoothd,docker,libvirtd,virtlockd,virtlogd,tlp,usbmuxd,tor,wireguard} /etc/runit/runsvdir/current

# Regenerate initrd image
xbps-reconfigure -fa

# Exit new system and go into the cd shell
exit 

# Reboot into the new system, don't forget to remove the usb
shutdown -r now

flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update --appstream
flatpak install --user flathub io.gitlab.librewolf-community com.bitwarden.desktop
