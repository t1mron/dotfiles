DRIVE="sda"
EXT4_OPTS="rw,noatime,discard"

# Delete a luks cont. if exist
head -c 3145728 /dev/urandom > /dev/$DRIVE; sync

# mbr
(echo o;echo w) | fdisk /dev/$DRIVE

# All Linux filesystem
(echo n;echo ;echo ;echo ;echo ;echo a;echo w) | fdisk /dev/$DRIVE

# Load encrypt modules
modprobe dm-mod

# Encrypt and open
cryptsetup luksFormat --type luks1 /dev/${DRIVE}1
cryptsetup open /dev/${DRIVE}1 crypt

# lvm2
pvcreate /dev/mapper/crypt
vgcreate linux /dev/mapper/crypt
lvcreate -L 50G linux -n void
lvcreate -L 8G linux -n swap
lvcreate -l +100%FREE linux -n home

# Formatting the partitions
mkfs.ext4 /dev/mapper/linux-void
mkfs.ext4 /dev/mapper/linux-home
mkswap /dev/mapper/linux-swap

# Mount partition
mount -o $EXT4_OPTS /dev/mapper/linux-void /mnt/
mkdir -p /mnt/home
mount -o $EXT4_OPTS /dev/mapper/linux-home /mnt/home

ARCH=x86_64-musl xbps-install -Su -R https://alpha.de.repo.voidlinux.org/current -r /mnt linux base-system base-devel dbus-elogind dbus-elogind-libs elogind polkit rtkit grub lvm2 socklog-void

for dir in dev proc sys run; do mount --rbind /$dir /mnt/$dir; mount --make-rslave /mnt/$dir; done

cp /etc/resolv.conf /mnt/etc/

DRIVE=$DRIVE EXT4_OPTS=$EXT4_OPTS PS1='(chroot) # ' chroot /mnt/ /bin/bash
chown root:root /
chmod 755 /

cat << EOF > /etc/xbps.d/10-ignore.conf
ignorepkg=sudo
ignorepkg=wpa_supplicant
ignorepkg=linux-firmware-amd
ignorepkg=linux-firmware-nvidia
ignorepkg=linux-firmware-broadcom
ignorepkg=linux-firmware-network
ignorepkg=ipw2100-firmware
ignorepkg=ipw2200-firmware
ignorepkg=zd1211-firmware
ignorepkg=wifi-firmware
ignorepkg=void-artwork
EOF

xbps-remove sudo wpa_supplicant linux-firmware-{amd,nvidia,broadcom,network} ipw2100-firmware ipw2200-firmware zd1211-firmware wifi-firmware void-artwork

# Add repos
#xbps-install -S void-repo-{nonfree,multilib,multilib-nonfree}

packagelist=(
  # Intel
  mesa-dri mesa-vulkan-intel vulkan-loader libva-intel-driver libva-utils sysfsutils 
  # XDG
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-user-dirs
  # Window manager 
  sway swaylock swayidle wofi foot wev Thunar lf wl-clipboard lxappearance neofetch
  # Thunar
  gvfs udiskie file-roller thunar-archive-plugin tumbler
  # Laptop
  tlp lm_sensors powertop 
  # Coreboot
  coreboot-utils flashrom
  # sound, bluetooth, vpn
  pipewire libspa-bluetooth bluez pulseaudio-utils pulsemixer
  # Coding  
  python3-pip git neovim
  # Office programs
  libreoffice okular zathura-pdf-mupdf nomacs imv
  # Terminal tools 
  htop gpm jq
  # Multimedia
  firefox mpv mpv-mpris playerctl yt-dlp telegram-desktop qbittorrent grim slurp spotify-tui spotifyd
  # IOS
  usbmuxd libimobiledevice
  # Security
  cryptsetup opendoas
  # Network
  iwd openresolv iwgtk wget curl
  # Virtualization
  docker docker-compose virt-manager libvirt qemu bridge-utils
)

xbps-install -Su ${packagelist[@]}

# symlinks
mkdir -p /etc/mpv/scripts/
ln -sf /usr/lib/mpv-mpris/mpris.so /etc/mpv/scripts/

git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles
cp -r $HOME/git/dotfiles/etc /
rm -rf $HOME/git

# Create user
useradd -G wheel,socklog,storage,video,audio,bluetooth,docker,kvm,libvirt -m -d /home/user user
passwd user
useradd -G wheel,storage -m -d /home/help help
passwd help

chsh -s /bin/bash user
chsh -s /bin/bash root

# User workflow
su user 
git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles

ln -sf $HOME/git/dotfiles/{.config,.fonts,.gtkrc-2.0,.vimrc,.bash_profile,.bashrc} ~/

# python scripts
pip install --user swaytools

# create default home folders
xdg-user-dirs-update
exit

# Set the time zone and a system clock
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc --localtime

# Don't enter a password twice
dd bs=512 count=4 if=/dev/urandom of=/boot/volume.key
cryptsetup -v luksAddKey -i 1 /dev/${DRIVE}1 /boot/volume.key
chmod 000 /boot/volume.key
chmod -R g-rwx,o-rwx /boot

LUKS_UUID=$(blkid -s UUID -o value /dev/${DRIVE}1)
ROOT_UUID=$(blkid -s UUID -o value /dev/mapper/linux-void)
HOME_UUID=$(blkid -s UUID -o value /dev/mapper/linux-home)
SWAP_UUID=$(blkid -s UUID -o value /dev/mapper/linux-swap)

echo "linux UUID=$LUKS_UUID /boot/volume.key luks" > /etc/crypttab

# lvm trim support
sed -i 's/issue_discards = 0/issue_discards = 1/' /etc/lvm/lvm.conf

cat << EOF > /etc/fstab
UUID=$ROOT_UUID / ext4 $EXT4_OPTS 0 1
UUID=$HOME_UUID /home ext4 $EXT4_OPTS 0 2
UUID=$SWAP_UUID none swap defaults 0 1
EOF

# Grub configuration
cat << EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR="Void"
GRUB_ENABLE_CRYPTODISK=y
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 resume=UUID=$SWAP_UUID"
GRUB_CMDLINE_LINUX="i915.modeset=1 enable_dc=2 i915.enable_rc6=1 i915.enable_psr=1 enable_fbc=1 i915.fastboot=1 i915.lvds_downclock=1 i915.semaphores=1 mitigations=off net.ifnames=0 ipv6.disable=1 modprobe.blacklist=pcspkr zram.num_devices=2 iomem=relaxed rd.luks.options=discard rd.lvm.vg=linux rd.luks.uuid=$LUKS_UUID"
EOF

# Install grub and create configuration
mkdir /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg

# enable services
ln -s /etc/sv/{dbus,polkitd,socklog-unix,nanoklogd,gpm,iwd,dhcpcd,bluetoothd,libvirtd,virtlockd,virtlogd,tlp,usbmuxd} /etc/runit/runsvdir/current

# Regenerate initrd image
xbps-reconfigure -fa

# Exit new system and go into the cd shell
exit 

# Reboot into the new system, don't forget to remove the usb
shutdown -r now
