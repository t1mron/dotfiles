rc-service sshd start
passwd

# Wipe disk before install
dd if=/dev/zero of=/dev/sda bs=446 count=1; sync
dd if=/dev/urandom of=/dev/sda bs=2M; sync

# if had a luks 
head -c 3145728 /dev/urandom > /dev/sda; sync 

# mbr
(echo o;echo w) | fdisk /dev/sda

# /dev/sda1 512M boot
(echo n;echo ;echo ;echo ;echo 1050623;echo a;echo w) | fdisk /dev/sda

# /dev/sda2 All Linux filesystem
(echo n;echo ;echo ;echo ;echo ;echo w) | fdisk /dev/sda

# Load encrypt modules 
modprobe dm-mod

# Encrypt and open /dev/sda2 
cryptsetup -v --cipher serpent-xts-plain64 --key-size 512 --hash whirlpool --use-random --verify-passphrase luksFormat --type luks1 /dev/sda2

cryptsetup open /dev/sda2 lvm

rc-service lvm start

pvcreate /dev/mapper/lvm
vgcreate matrix /dev/mapper/lvm
lvcreate -l +100%FREE matrix -n rootvol

# Formatting the partitions
mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/mapper/matrix-rootvol

# Mount partitions and create folders
mount /dev/matrix/rootvol /mnt/gentoo
mkdir /mnt/gentoo/boot
mount /dev/sda1 /mnt/gentoo/boot

# Download stage3-amd64-openrc 
cd /mnt/gentoo
LATEST=$(wget --quiet https://mirror.bytemark.co.uk/gentoo/releases/amd64/autobuilds/latest-stage3-amd64-openrc.txt -O-| tail -n 1 | cut -d " " -f 1)
wget -q --show-progress "https://mirror.bytemark.co.uk/gentoo/releases/amd64/autobuilds/$LATEST"

# Check sha512sum 
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
/dev/sda1 /boot ext4 defaults,noatime 0 2
/dev/mapper/matrix-rootvol / ext4 noatime 0 1

tmpfs /var/tmp         tmpfs rw,nosuid,noatime,nodev,size=16G,mode=1777 0 0
tmpfs /var/tmp/portage tmpfs rw,nosuid,noatime,nodev,size=16G,mode=775,uid=portage,gid=portage,x-mount.mkdir=775 0 0
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
MAKEOPTS="-j9"
EMERGE_DEFAULT_OPTS="--jobs=9 --load-average=9"
FEATURES="buildpkg ccache"
USE="X alsa bluetooth elogind policykit udisks dbus gpm vaapi lm-sensors"
USE="${USE} -gnome -wayland -systemd -pulseaudio -firmware"
ACCEPT_LICENSE="-* @FREE"
INPUT_DEVICES="libinput"
VIDEO_CARDS="intel i915 i965"
EOF

# sync  portage
emerge-webrsync
emerge --sync

emerge --ask -q -v dev-util/ccache dev-lang/rust-bin  

# update @word
emerge --ask -q -v --update --deep --newuse @world

# fix circular dependencies - harfbuzz freetype 
USE="-harfbuzz" emerge -1 virtual/libintl app-arch/bzip2 virtual/libiconv media-libs/libpng dev-libs/libpcre media-libs/freetype media-gfx/graphite2 sys-apps/util-linux dev-libs/glib media-libs/harfbuzz --nodeps
emerge -1 media-libs/freetype media-libs/harfbuzz

packagelist=(
  # basic
  sys-kernel/gentoo-sources sys-kernel/genkernel sys-fs/lvm2 sys-boot/grub:2
  # Terminal tools 
  app-admin/syslog-ng sys-apps/mlocate
  # Security
  app-admin/doas sys-fs/cryptsetup
  # Network
  net-misc/dhcpcd
)

emerge --ask -q -v ${packagelist[@]}

# Create user
useradd -G wheel -m -d /home/user user
passwd user
passwd

cat << EOF > /etc/doas.conf
permit persist :wheel
EOF

# set the time zone and a system clock
echo "Europe/Moscow" > /etc/timezone
emerge --config sys-libs/timezone-data
hwclock --systohc --utc

# Set default locale
cat << EOF > /etc/locale.gen
en_US.UTF-8 UTF-8
ru_RU.UTF-8 UTF-8
EOF

# update locale
locale-gen

# set system locale
cat << EOF > /etc/env.d/02locale
LANG="en_US.UTF-8"
LC_COLLATE="C"
EOF

# set hostname
cat << EOF > /etc/conf.d/hostname
hostname="gentoo"
EOF

# set the host
cat << EOF > /etc/hosts
127.0.0.1     gentoo.homenetwork gentoo localhost
EOF

rc-update add syslog-ng default
rc-update add sshd default
rc-update add gpm default
rc-update add lvm boot

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

# compile
genkernel --luks --lvm --no-zfs --compress-initramfs-type=zstd --mountboot all

# Install and create grub configuration
cat << EOF > /etc/default/grub
GRUB_DISTRIBUTOR="Gentoo"
GRUB_CMDLINE_LINUX="dolvm crypt_root=UUID=4675ba23-f73d-424c-a841-67ea993fabd7"
EOF

# create grub configuration
grub-install --root-directory=/ --boot-directory=/boot /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# reboot
exit
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
reboot

cat << EOF > /var/tmp/ccache/ccache.conf
# Maximum cache size to maintain
max_size = 100.0G

# Allow others to run 'ebuild' and share the cache.
umask = 002

# Preserve cache across GCC rebuilds and
# introspect GCC changes through GCC wrapper.
compiler_check = %compiler% -v

# I expect 1.5M files. 300 files per directory.
cache_dir_levels = 3
EOF

emerge --ask -q -v dev-vcs/git app-eselect/eselect-repository

# ricerlay - lemonbar; guru - pfetch 
eselect repository enable ricerlay guru
eselect repository add t1mron_overlay git https://github.com/t1mron/t1mron_overlay
eselect repository add tlp git https://github.com/dywisor/tlp-portage
emaint -a sync

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
  sys-process/cronie app-portage/genlop app-portage/eix sys-process/htop media-video/libva-utils
  # Multimedia
  www-client/firefox media-gfx/scrot media-gfx/sxiv net-misc/youtube-dl media-video/mpv
  # Look and feel
  lxde-base/lxappearance app-misc/pfetch media-fonts/dejavu
  # Bash
  app-shells/hstr
  # Compiler 
  sys-devel/clang dev-util/ninja
  # Network
  net-wireless/iwd net-wireless/iw
  # Binhost
  www-servers/lighttpd
)

emerge --ask -q -v ${packagelist[@]}

cat << EOF > /etc/lighttpd/lighttpd.conf
var.basedir  = "/var/www/localhost"
var.logdir   = "/var/log/lighttpd"
var.statedir = "/var/lib/lighttpd"

server.modules = (
    "mod_access",
    "mod_accesslog",
    "mod_alias"
)

include "mime-types.conf"

server.username      = "lighttpd"
server.groupname     = "lighttpd"
server.document-root = var.basedir + "/htdocs"
server.pid-file      = "/run/lighttpd.pid"
server.errorlog      = var.logdir  + "/error.log"
server.indexfiles    = ("index.php", "index.html", "index.htm", "default.htm")
server.follow-symlink = "enable"
server.use-ipv6 = "disable"
static-file.exclude-extensions = (".php", ".pl", ".cgi", ".fcgi")
accesslog.filename   = var.logdir + "/access.log"
url.access-deny = ("~", ".inc")
alias.url = ( "/packages" => "/var/cache/binpkgs" )
EOF

rc-update add lighttpd default
rc-update add cronie default
rc-service lighttpd start
rc-service cronie start
