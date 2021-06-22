# migrate from stable to sid
apt install ssh sudo 

cat << EOF > /etc/apt/sources.list
deb     http://deb.devuan.org/merged ceres main
deb-src http://deb.devuan.org/merged ceres main
EOF

apt-get update && apt-get upgrade && apt-get dist-upgrade && apt-get autoremove && reboot
apt install linux-image-5.10.0-7-amd64

# basic 
apt install sysv-rc-conf network-manager iwd wget curl vim git

# Window manager
apt install bspwm sxhkd xserver-xorg-core xinit xinput x11-utils x11-xserver-utils rxvt-unicode polybar suckless-tools ranger rofi fonts-font-awesome fonts-hack arandr autorandr

# Laptop (soon)

# wi-fi, sound, bluetooth, vpn (soon)

# Office programs
apt install texlive-latex-recommended zathura

# vim plugins
apt install python3-pip
pip3 install pynvim pylint

PlugInstall
CocInstall coc-vimlsp coc-python coc-sh coc-vimtex coc-explorer

# Look and feel
apt install neofetch zsh zsh-antigen

# Utilities
apt install man-db flameshot redshift mpv sxiv

# System tools 
apt install htop 

# Multimedia
apt install firefox-esr telegram-desktop 

# Virtualisation (soon)

# Security 
apt install ufw 
ufw enable 

# Create user
useradd -G sudo -m -d /home/user user
passwd user
useradd -G sudo -m -d /home/help help
passwd help

# dotfiles
git clone --depth=1 https://github.com/t1mron/dotfiles_devuan $HOME/git/dotfiles_devuan
cp -r $HOME/git/dotfiles_devuan/. $HOME/ && rm -rf $HOME/root .git LICENSE README.md readme.txt
sudo cp -r $HOME/git/dotfiles_devuan/root/. /

git clone https://github.com/alexanderjeurissen/ranger_devicons $HOME/.config/ranger/plugins/ranger_devicons


wget 
sudo dpkg -i
