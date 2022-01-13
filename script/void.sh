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

xbps-install -Su -R https://alpha.de.repo.voidlinux.org/current -r /mnt linux base-minimal elogind grub lvm2

cp /etc/resolv.conf /mnt/etc/

mount --rbind /sys /mnt/sys && mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc

PS1='(chroot) # ' chroot /mnt/ /bin/bash
chown root:root /
chmod 755 /

cat << EOF > /etc/xbps.d/10-ignore.conf
ignorepkg=linux-firmware-amd
ignorepkg=linux-firmware-intel
ignorepkg=linux-firmware-nvidia
ignorepkg=linux-firmware-broadcom
ignorepkg=linux-firmware-network
EOF

xbps-remove linux-firmware-amd linux-firmware-intel linux-firmware-nvidia linux-firmware-broadcom linux-firmware-network

packagelist=(
  # Xorg
  xorg-server xf86-input-libinput xauth xinit xrandr xev xprop xsetroot xkill xclip xcalib 
  # Intel
  mesa-dri xf86-video-intel libva-intel-driver libva-utils vulkan-loader mesa-vulkan-intel 
  # Window manager 
  bspwm sxhkd polybar xterm rofi Thunar jgmenu slock xdg-user-dirs
  # Thunar
  gvfs file-roller thunar-archive-plugin tumbler udisks2
  # Laptop
  tlp lm_sensors  
  # Coreboot
  coreboot-utils flashrom
  # sound, bluetooth, vpn
  pipewire libspa-bluetooth pavucontrol pulseaudio-utils bluez blueman
  # Coding  
  python3-pip git neovim
  # Office programs
  okular nomacs feh gimp
  # Terminal tools 
  htop openssh man-db gpm wget curl playerctl mlocate
  # Multimedia
  firefox mpv telegram-desktop qbittorrent flameshot 
  # Look and feel
  zsh lxappearance pfetch
  # Security
  cryptsetup
  # Network
  iwd openresolv iwgtk
  # Virtualization
  docker docker-compose
)

xbps-install -Su ${packagelist[@]}

git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles
cp -r $HOME/git/dotfiles/root/void/. /mnt/
rm -rf $HOME/git

# Create user
useradd -G wheel,rfkill,docker -m -d /home/user user
passwd user
useradd -G wheel -m -d /home/help help
passwd help

chsh -s /bin/zsh user

# Set the time zone and a system clock
ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc --utc

# Update current locale
xbps-reconfigure -f glibc-locales

# hibernation
# add

su user 
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $HOME/.zsh/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting $HOME/.zsh/zsh-syntax-highlighting
git clone --depth=1 https://github.com/woefe/git-prompt.zsh $HOME/.zsh/git-prompt

git clone --depth=1 https://github.com/t1mron/dotfiles $HOME/git/dotfiles
cp -r $HOME/git/dotfiles/user/void/. ~/

exit

# Don't enter a password twice
dd bs=1 count=64 if=/dev/urandom of=/boot/volume.key
cryptsetup -v luksAddKey -i 1 /dev/sda1 /boot/volume.key
chmod 000 /boot/volume.key
chmod -R g-rwx,o-rwx /boot

# Create grub configuration
cat << EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR="Void"
GRUB_CMDLINE_LINUX="iomem=relaxed tsc=unstable rd.lvm.vg=sda1_crypt rd.luks.uuid=$(blkid -s UUID -o value /dev/sda1)"
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=4"
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

ln -s /etc/sv/{dbus,polkitd,elogind,iwd,ead,bluetoothd,docker,tlp} /var/service
