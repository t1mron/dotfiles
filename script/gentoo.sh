# Wipe disk before install
dd if=/dev/zero of=/dev/sda bs=446 count=1; sync
dd if=/dev/urandom of=/dev/sda bs=2M; sync

# Delete a luks cont. if exist
head -c 3145728 /dev/urandom > /dev/sda; sync

# /dev/sda1 All Linux filesystem
(echo n;echo ;echo ;echo ;echo ;echo a;echo w) | fdisk /dev/sda

# Load encrypt modules
modprobe dm-mod

# Encrypt and open /dev/sda1
cryptsetup -v --cipher serpent-xts-plain64 --key-size 512 --hash whirlpool --use-random --verify-passphrase luksFormat --type luks1 /dev/sda1

cryptsetup open /dev/sda1 lvm

rc-service lvm start

pvcreate /dev/mapper/lvm
vgcreate matrix /dev/mapper/lvm
lvcreate -l +100%FREE matrix -n rootvol

# Formatting the partitions
mkfs.ext4 /dev/mapper/matrix-rootvol

# Mount partition
mount /dev/matrix/rootvol /mnt/gentoo

# Download stage3-amd64-openrc 
cd /mnt/gentoo
LATEST=$(wget --quiet https://mirror.bytemark.co.uk/gentoo/releases/amd64/autobuilds/latest-stage3-amd64-openrc.txt -O-| tail -n 1 | cut -d " " -f 1)
wget -q --show-progress "https://mirror.bytemark.co.uk/gentoo/releases/amd64/autobuilds/$LATEST"

# Check sha512sum (soon)
wget -q --show-progress "https://mirror.bytemark.co.uk/gentoo/releases/amd64/autobuilds/${LATEST}.DIGESTS.asc"
gpg --verify stage3-*.DIGESTS.asc

# unpack archive
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
rm -rf stage3-*.tar.xz

# create repos.conf directory
mkdir --parents /mnt/gentoo/etc/portage/repos.conf

# copy ebuild-files repository 
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

# copy resolv.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

# mount partitions for chroot
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

# chroot
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"

# edit fstab 
cat << EOF > /etc/fstab
/dev/mapper/matrix-rootvol / ext4 noatime 0 1

tmpfs /var/tmp         tmpfs rw,nosuid,noatime,nodev,size=4G,mode=1777 0 0
tmpfs /var/tmp/portage tmpfs rw,nosuid,noatime,nodev,size=4G,mode=775,uid=portage,gid=portage,x-mount.mkdir=775 0 0
EOF

# mount tmpfs
mount /var/tmp/portage

# edit make.conf   
cat << \EOF > /etc/portage/make.conf
COMMON_FLAGS="-march=core2 -O2 -pipe"
CPU_FLAGS_X86="mmx mmxext sse sse2 sse3 ssse3"

CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"

PORTDIR="/var/db/repos/gentoo"
DISTDIR="/var/cache/distfiles"
PKGDIR="/var/cache/binpkgs"

LC_MESSAGES=C
MAKEOPTS="-j3"
EMERGE_DEFAULT_OPTS="--jobs=3 --load-average=3 -G"
PORTAGE_BINHOST="http://192.168.1.50/packages"
USE="X alsa bluetooth elogind policykit udisks dbus gpm vaapi lm-sensors"
USE="${USE} -gnome -wayland -systemd -pulseaudio -firmware"
ACCEPT_LICENSE="-* @FREE"
INPUT_DEVICES="libinput"
VIDEO_CARDS="intel i915 i965"
EOF

# sync  portage
emerge-webrsync
emerge --sync

# update @word
emerge --ask -q -v --update --deep --newuse @world

# fix circular dependencies - harfbuzz freetype 
USE="-harfbuzz" emerge -1 virtual/libintl app-arch/bzip2 virtual/libiconv media-libs/libpng dev-libs/libpcre media-libs/freetype media-gfx/graphite2 sys-apps/util-linux dev-libs/glib media-libs/harfbuzz --nodeps
emerge -1 media-libs/freetype media-libs/harfbuzz

emerge --ask -q -v dev-vcs/git app-eselect/eselect-repository

# petkovich - lemonbar; guru - pfetch
eselect repository enable petkovich guru
eselect repository add t1mron_overlay git https://github.com/t1mron/t1mron_overlay
eselect repository add tlp git https://github.com/dywisor/tlp-portage
emaint -a sync

git clone https://github.com/t1mron/dotfiles $HOME/dotfiles
cp -r $HOME/dotfiles/root/gentoo/. /
rm -rf $HOME/dotfiles

cat << EOF > /etc/portage/package.use/custom
sys-boot/grub:2 device-mapper
app-admin/doas persist
x11-misc/lemonbar xft 
x11-terms/rxvt-unicode 24-bit-color 256-color unicode3 wide-glyphs xft
www-client/firefox hwaccel

# firefox
media-libs/libpng apng
media-libs/libvpx postproc

# pavucontrol
media-plugins/alsa-plugins pulseaudio

# zathura
app-text/poppler cairo

# spacefm
media-libs/freetype harfbuzz
EOF

cat << EOF > /etc/portage/package.accept_keywords
app-misc/nnn 
app-admin/doas 
x11-misc/xdo 
lxde-base/lxappearance 
app-misc/pfetch
x11-misc/lemonbar

# tlp
app-laptop/tlp 
sys-power/linux-x86-power-tools 
EOF

cat << EOF > /etc/portage/package.mask
*/*::ricerlay
*/*::guru
*/*::t1mron_overlay
EOF

cat << EOF > /etc/portage/package.unmask
x11-terms/rxvt-unicode::t1mron_overlay
x11-misc/lemonbar::ricerlay
app-misc/pfetch::guru
EOF

packagelist=(
  # basic
  sys-kernel/gentoo-sources sys-kernel/genkernel sys-fs/lvm2 sys-boot/grub:2
  # Coding 
  dev-python/pip app-editors/vim
  # Xorg
  x11-base/xorg-server x11-apps/xinit x11-apps/xev x11-apps/xsetroot x11-apps/xkill x11-misc/xclip x11-apps/xrandr x11-apps/xset x11-misc/xdo
  # Window manager
  x11-wm/bspwm x11-misc/sxhkd x11-terms/rxvt-unicode x11-misc/spacefm x11-misc/rofi x11-misc/lemonbar app-misc/nnn x11-misc/slock
  # Laptop
  sys-power/acpid sys-power/acpi app-laptop/tlp sys-power/powertop app-laptop/thinkfan 
  # sound, bluetooth, vpn
  media-video/pipewire media-sound/pavucontrol media-sound/alsa-utils net-wireless/bluez
  # Office programs
  app-text/zathura app-text/zathura-meta app-text/texlive
  # Terminal tools 
  app-admin/syslog-ng sys-apps/mlocate sys-process/cronie app-portage/genlop app-portage/eix sys-process/htop media-video/libva-utils
  # Bash
  app-shells/hstr
  # Multimedia
  www-client/firefox media-gfx/scrot media-gfx/sxiv net-misc/youtube-dl media-video/mpv
  # Look and feel
  lxde-base/lxappearance app-misc/pfetch media-fonts/dejavu
  # Security
  app-admin/doas sys-fs/cryptsetup
  # Compiler 
  dev-lang/rust-bin
  # Network
  net-misc/dhcpcd net-wireless/iwd net-wireless/iw
)

emerge --ask -q -v ${packagelist[@]}

# Create user
useradd -G wheel,audio,plugdev -m -d /home/user user
passwd user
useradd -G wheel,audio,plugdev -m -d /home/help help
passwd help

# set the time zone and a system clock
emerge --config sys-libs/timezone-data
hwclock --systohc --utc

# update locale
locale-gen

#####################
rc-update add bluetooth default
rc-update add syslog-ng default
rc-update add thinkfan default
rc-update add cronie default
rc-update add bluez default
rc-update add acpid default
rc-update add dbus default
rc-update add gpm default
rc-update add tlp default

rc-update add elogind boot
rc-update add lvm boot

###################
# select kernel
eselect kernel set 1 

# deblob
cd /usr/src/linux
version=5.10.52
main=${version%.*}
url=https://linux-libre.fsfla.org/pub/linux-libre/releases/

wget $url$version-gnu/deblob-$main
wget $url$version-gnu/deblob-$main.sign
wget $url$version-gnu/deblob-check
wget $url$version-gnu/deblob-check.sign

chmod 744 deblob-$main deblob-check

wget https://linux-libre.fsfla.org/pub/linux-libre/SIGNING-KEY.linux-libre
gpg --import SIGNING-KEY.linux-libre

gpg --verify deblob-$main.sign deblob-$main
gpg --verify deblob-check.sign deblob-check

emerge --ask --noreplace --oneshot dev-lang/python:3.8

PYTHON="python3.8" ./deblob-$main

genkernel --luks --lvm --no-zfs --compress-initramfs-type=zstd --mountboot all 

# create grub configuration
mkdir /boot/grub
grub-mkconfig -o /boot/grub/libreboot_grub.cfg

###############
# reboot
exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
reboot

powertop --calibrate
