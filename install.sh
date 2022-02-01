DRIVE="sda"

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
mkfs.btrfs -L void /dev/mapper/linux-void
mkfs.ext4 /dev/mapper/linux-home
mkswap /dev/mapper/linux-swap

# ... and btrfs subvolumes
BTRFS_OPTS="rw,noatime,ssd,space_cache,commit=120"
EXT4_OPTS="rw,noatime,discard"
mount -o $BTRFS_OPTS /dev/mapper/linux-void /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@snapshots

# Unmount and remount with the corect partitions
umount /mnt

# Remount the partitions
mount -o $BTRFS_OPTS,subvol=@ /dev/mapper/linux-void /mnt
mkdir -p /mnt/{home,.snapshots}
mount -o $EXT4_OPTS /dev/mapper/linux-home /mnt/home
mount -o $BTRFS_OPTS,subvol=@snapshots /dev/mapper/linux-void /mnt/.snapshots

# Nested partitions. Snapshots don't work resursively
mkdir -p /mnt/var/cache
btrfs subvolume create /mnt/var/cache/xbps
btrfs subvolume create /mnt/var/tmp
btrfs subvolume create /mnt/srv

xbps-install -Su -R https://alpha.de.repo.voidlinux.org/current -r /mnt base-minimal grub-btrfs lvm2 linux dosfstools e2fsprogs btrfs-progs ncurses dhcpcd dbus-elogind dbus-elogind-libs elogind polkit rtkit

for dir in dev proc sys run; do mount --rbind /$dir /mnt/$dir; mount --make-rslave /mnt/$dir; done

cp /etc/resolv.conf /mnt/etc/

DRIVE=$DRIVE BTRFS_OPTS=$BTRFS_OPTS EXT4_OPTS=$EXT4_OPTS PS1='(chroot) # ' chroot /mnt/ /bin/bash
chown root:root /
chmod 755 /

# Add repos
#xbps-install -S void-repo-{nonfree,multilib,multilib-nonfree}

packagelist=(
  # Intel
  mesa-dri mesa-vulkan-intel vulkan-loader libva-intel-driver libva-intel-utils sysfsutils 
  # XDG
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-user-dirs
  # Window manager 
  sway swaylock swayidle wofi foot wev Thunar lf zsh wl-clipboard
  # Thunar
  gvfs udiskie file-roller thunar-archive-plugin
  # Laptop
  tlp lm_sensors powertop 
  # Coreboot
  coreboot-utils flashrom
  # sound, bluetooth, vpn
  pipewire alsa-pipewire libjack-pipewire pavucontrol pulseaudio-utils bluez blueman
  # Coding  
  python3-pip git neovim
  # Office programs
  libreoffice okular zathura-pdf-mupdf nomacs imv
  # Terminal tools 
  htop gpm
  # Multimedia
  firefox mpv mpv-mpris playerctl yt-dlp telegram-desktop qbittorrent grim slurp
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
ln -s /usr/lib/mpv-mpris/mpris.so /etc/mpv/scripts/
ln -s /bin/telegram-desktop /bin/telegram

git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles
cp -r $HOME/git/dotfiles/etc /
rm -rf $HOME/git

# Create user
useradd -G users,wheel,docker,kvm,libvirt -m -d /home/user user
passwd user
useradd -G users,wheel -m -d /home/help help
passwd help

chsh -s /bin/zsh user
chsh -s /bin/bash root

# User workflow
su user 
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $HOME/.zsh/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting $HOME/.zsh/zsh-syntax-highlighting
git clone --depth=1 https://github.com/woefe/git-prompt.zsh $HOME/.zsh/git-prompt
git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles

ln -sf $HOME/git/dotfiles/{.config,.fonts,.vimrc,.zprofile,.zshrc} ~/

# python scripts
pip install --user swaytools
exit

# Set the time zone and a system clock
ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc --utc

# Update current locale
xbps-reconfigure -f glibc-locales

# Pipewire - ALSA integration
mkdir -p /etc/alsa/conf.d
ln -s /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d
ln -s /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d

# Don't enter a password twice
dd bs=1 count=64 if=/dev/urandom of=/boot/volume.key
cryptsetup -v luksAddKey -i 1 /dev/${DRIVE}1 /boot/volume.key
chmod 000 /boot/volume.key
chmod -R g-rwx,o-rwx /boot

LUKS_UUID=$(blkid -s UUID -o value /dev/${DRIVE}1)
ROOT_UUID=$(blkid -s UUID -o value /dev/mapper/linux-void)
HOME_UUID=$(blkid -s UUID -o value /dev/mapper/linux-home)
SWAP_UUID=$(blkid -s UUID -o value /dev/mapper/linux-swap)

echo "linux UUID=$LUKS_UUID /boot/volume.key luks" > /etc/crypttab

cat << EOF > /etc/default/grub
UUID=$ROOT_UUID / btrfs $BTRFS_OPTS,subvol=@ 0 1
UUID=$ROOT_UUID /.snapshots btrfs $BTRFS_OPTS,subvol=@snapshots 0 2
UUID=$HOME_UUID /home ext4 $EXT4_OPTS 0 2
UUID=$SWAP_UUID none swap defaults 0 1
tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0
EOF

# Grub configuration
cat << EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR="Void"
GRUB_ENABLE_CRYPTODISK=y
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 resume=UUID=$SWAP_UUID zswap.enabled=0"
GRUB_CMDLINE_LINUX="i915.modeset=1 enable_dc=2 i915.enable_rc6=1 i915.enable_psr=1 enable_fbc=1 i915.fastboot=1 i915.lvds_downclock=1 i915.semaphores=1 mitigations=off net.ifnames=0 ipv6.disable=1 modprobe.blacklist=pcspkr zram.num_devices=2 iomem=relaxed rd.lvm.vg=linux rd.luks.uuid=$LUKS_UUID)"
EOF

# Install grub and create configuration
mkdir /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg

# enable services
ln -s /etc/sv/{dbus,polkitd,gpm,iwd,dhcpcd,bluetoothd,docker,libvirtd,virtlockd,virtlogd,tlp,usbmuxd} /etc/runit/runsvdir/current

# Regenerate initrd image
xbps-reconfigure -fa

# Exit new system and go into the cd shell
exit 

# Reboot into the new system, don't forget to remove the usb
shutdown -r now
