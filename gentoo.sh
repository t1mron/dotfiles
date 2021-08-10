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

# Download stage - nomultilib_64bit/openrc
cd /mnt/gentoo
LATEST=$(wget --quiet https://mirror.bytemark.co.uk/gentoo/releases/amd64/autobuilds/latest-stage3-amd64-nomultilib-openrc.txt -O-| tail -n 1 | cut -d " " -f 1)
wget -q --show-progress "https://mirror.bytemark.co.uk/gentoo/releases/amd64/autobuilds/$LATEST"

# Check sha512sum (soon)

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
#CPU_FLAGS_X86="mmx sse sse2 sse3 ssse3 sse4 sse4a sse4_1"

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
USE="X alsa bluetooth elogind dbus gpm vaapi lm-sensors screencast"
USE="${USE} -gnome -systemd -pulseaudio -firmware"
ACCEPT_LICENSE="-* @FREE"
VIDEO_CARDS="intel i915 i965"
EOF

cat << \EOF > /etc/portage/make.conf
COMMON_FLAGS="-march=core2 -O2 -pipe"
#CPU_FLAGS_X86="mmx sse sse2 sse3 ssse3 sse4 sse4a sse4_1"

CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"

# NOTE: This stage was built with the bindist Use flag enabled
PORTDIR="/var/db/repos/gentoo"
DISTDIR="/var/cache/distfiles"
PKGDIR="/var/cache/binpkgs"

LC_MESSAGES=C
MAKEOPTS="-j9"
EMERGE_DEFAULT_OPTS="--jobs=9 --load-average=9"
FEATURES="buildpkg"
USE="X alsa bluetooth elogind dbus gpm vaapi lm-sensors screencast"
USE="${USE} -gnome -systemd -pulseaudio -firmware"
ACCEPT_LICENSE="-* @FREE"
VIDEO_CARDS="intel i915 i965"
EOF

# sync  portage
emerge-webrsync
emerge --sync

# update @word
emerge --ask -q -v --update --deep --newuse @world

# fix circular dependencies - harfbuzz freetype 
USE=-harfbuzz emerge --ask -q -v --oneshot freetype

###############
emerge --ask -q -v dev-vcs/git app-eselect/eselect-repository

# petkovich - lemonbar; guru - pfetch; pf4public - ungoogled-chromium
eselect repository enable petkovich guru pf4public
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

# pipewire
media-video/pipewire jack-client pipewire-alsa
# zathura-meta
app-text/poppler cairo
# spacefm 
media-libs/freetype harfbuzz
# latex
media-libs/harfbuzz icu
# neovim
app-editors/neovim LUA_SINGLE_TARGET: luajit -lua5-1
dev-lua/luv LUA_SINGLE_TARGET: luajit -lua5-1
dev-lua/lpeg LUA_TARGETS: luajit -lua5-1
dev-lua/mpack LUA_TARGETS: luajit -lua5-1 
EOF

cat << EOF > /etc/portage/package.accept_keywords
app-misc/nnn 
app-admin/doas 
x11-misc/xdo 
lxde-base/lxappearance 
app-editors/neovim 
x11-terms/rxvt-unicode

# tlp
app-laptop/tlp 
sys-power/linux-x86-power-tools 
EOF

packagelist=(
  # basic
  dev-lang/rust-bin sys-kernel/gentoo-sources sys-kernel/genkernel sys-fs/lvm2 sys-boot/grub:2 x11-libs/intel-driver-g45-h264
  # Coding 
  dev-python/pip app-editors/neovim
  # Xorg
  x11-base/xorg-server x11-apps/xinit x11-apps/xev x11-apps/xsetroot x11-apps/xkill x11-misc/xclip x11-apps/xrandr x11-apps/xset x11-misc/xdo
  # Window manager
  x11-wm/bspwm x11-misc/sxhkd x11-misc/spacefm x11-misc/rofi x11-misc/lemonbar app-misc/nnn x11-misc/slock
  # Laptop (soon)
  sys-power/acpid sys-power/acpi app-laptop/tlp app-laptop/tp_smapi sys-power/powertop app-laptop/thinkfan 
  # sound, bluetooth, vpn (soon)
  media-video/pipewire media-sound/alsa-utils media-sound/pavucontrol net-wireless/bluez
  # Office programs
  app-text/zathura app-text/zathura-meta app-text/texlive
  # Terminal tools 
  app-admin/syslog-ng sys-process/cronie sys-apps/mlocate app-portage/eix sys-process/htop media-video/libva-utils
  # Multimedia
  www-client/firefox media-gfx/scrot media-gfx/sxiv net-misc/youtube-dl net-im/telegram-desktop media-video/mpv
  # Look and feel
  app-shells/zsh lxde-base/lxappearance app-misc/pfetch media-fonts/dejavu
  # Security
  app-admin/doas
  # Network
  net-misc/dhcpcd net-wireless/iwd net-wireless/iw
)

emerge --ask -q -v ${packagelist[@]}

# Create user
useradd -G wheel -m -d /home/user user
passwd user
useradd -G wheel -m -d /home/help help
passwd help

# default shell bash
chsh -s /bin/zsh user
chsh -s /bin/bash help

# set the time zone and a system clock
emerge --config sys-libs/timezone-data
hwclock --systohc --utc

# update locale
locale-gen

su user
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $HOME/.zsh/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting $HOME/.zsh/zsh-syntax-highlighting
git clone --depth=1 https://github.com/woefe/git-prompt.zsh $HOME/.zsh/git-prompt
exit

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

genkernel --luks --lvm --no-zfs --compress-initramfs-type=zstd --mountboot --install initramfs

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
