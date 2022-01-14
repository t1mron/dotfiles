# Delete a luks cont. if exist
head -c 3145728 /dev/urandom > /dev/sda; sync

# mbr
(echo o;echo w) | fdisk /dev/sda

# /dev/sda1 All Linux filesystem
(echo n;echo ;echo ;echo ;echo ;echo a;echo w) | fdisk /dev/sda

# Load encrypt modules
modprobe dm-mod

# Encrypt and open /dev/sda1
cryptsetup luksFormat --type luks1 /dev/sda1

cryptsetup open /dev/sda1 sda1_crypt

pvcreate /dev/mapper/sda1_crypt
vgcreate vg1 /dev/mapper/sda1_crypt
lvcreate -l +100%FREE vg1 -n root 

# Formatting the partitions
mkfs.ext4 /dev/mapper/vg1-root

# Mount partition
mount /dev/mapper/vg1-root /mnt/

xbps-install -Su -R https://alpha.de.repo.voidlinux.org/current -r /mnt linux base-system elogind grub lvm2

cp /etc/resolv.conf /mnt/etc/

mount --rbind /sys /mnt/sys && mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc

PS1='(chroot) # ' chroot /mnt/ /bin/bash
chown root:root /
chmod 755 /

cat << EOF > /etc/xbps.d/10-ignore.conf
ignorepkg=wpa_supplicant
ignorepkg=sudo
EOF

xbps-remove wpa_supplicant sudo

packagelist=(
  # Xorg
  xorg-server xf86-input-libinput xauth xinit xrandr xev xprop xsetroot xkill xclip xcalib xset
  # Intel
  mesa-dri xf86-video-intel libva-intel-driver libva-utils sysfsutils 
  # Window manager 
  bspwm sxhkd polybar xterm rofi Thunar jgmenu xss-lock slock xdg-user-dirs
  # Thunar
  gvfs udiskie file-roller thunar-archive-plugin tumbler
  # Laptop
  tlp lm_sensors  
  # Coreboot
  coreboot-utils flashrom
  # sound, bluetooth, vpn
  pipewire alsa-pipewire libjack-pipewire pavucontrol pulseaudio-utils bluez blueman
  # Coding  
  python3-pip git neovim
  # Office programs
  okular nomacs feh gimp
  # Terminal tools 
  htop gpm playerctl mlocate
  # Multimedia
  firefox mpv telegram-desktop qbittorrent flameshot 
  # Look and feel
  zsh lxappearance pfetch
  # Security
  cryptsetup opendoas
  # Network
  iwd openresolv iwgtk wget curl
  # Virtualization
  docker docker-compose flatpak
)

xbps-install -Su ${packagelist[@]}

git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles
cp -r $HOME/git/dotfiles/root/void/. /
rm -rf $HOME/git

# Create user
useradd -G wheel,audio,video,storage,docker -m -d /home/user user
passwd user
useradd -G wheel,storage -m -d /home/help help
passwd help

chsh -s /bin/zsh user
chsh -s /bin/bash help
chsh -s /bin/bash root

# User workflow
su user 
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $HOME/.zsh/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting $HOME/.zsh/zsh-syntax-highlighting
git clone --depth=1 https://github.com/woefe/git-prompt.zsh $HOME/.zsh/git-prompt
git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles
cp -r $HOME/git/dotfiles/user/void/. ~/
flatpak install flathub com.discordapp.Discord org.onlyoffice.desktopeditors
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

# hibernation
fallocate -l 8G /swapfile
mkswap /swapfile
chmod u=rw,go= /swapfile
swapon /swapfile

# Don't enter a password twice
dd bs=1 count=64 if=/dev/urandom of=/boot/volume.key
cryptsetup -v luksAddKey -i 1 /dev/sda1 /boot/volume.key
chmod 000 /boot/volume.key
chmod -R g-rwx,o-rwx /boot

# Create grub configuration
# filefrag -v /swapfile
cat << EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR="Void"
GRUB_CMDLINE_LINUX="i915.modeset=1 i915.fastboot=1 i915.enable_dc=2 i915.enable_rc6=1 i915.enable_fbc=1 i915.lvds_downclock=1 noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off modprobe.blacklist=pcspkr zram.num_devices=2 net.ifnames=0 iomem=relaxed rd.lvm.vg=vg1 rd.luks.uuid=$(blkid -s UUID -o value /dev/sda1)"
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 resume=/dev/mapper/vg1-root resume_offset=30152704 zswap.enabled=0"
GRUB_ENABLE_CRYPTODISK=y
EOF

# Regenerate initrd image
xbps-reconfigure -fa

# Install grub and create configuration
mkdir /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Exit new system and go into the cd shell
exit 

# Reboot into the new system, don't forget to remove the usb
reboot

ln -s /etc/sv/{dbus,polkitd,elogind,iwd,dhcpcd,bluetoothd,docker,tlp} /var/service
