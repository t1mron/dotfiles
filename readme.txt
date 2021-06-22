# basic 
apt install sysv-rc-conf network-manager iwd wget vim git

# Window manager
apt install bspwm sxhkd xserver-xorg-core xinit xinput x11-utils x11-xserver-utils polybar ranger rxvt-unicode rofi fonts-font-awesome fonts-hack arandr autorandr

# Laptop (soon)

# wi-fi, sound, bluetooth, vpn (soon)

# Office programs
apt install texlive-full zathura

# vim plugins
apt install python3-pip
pip3 install pynvim pylint

PlugInstall
CocInstall coc-vimlsp coc-python coc-sh coc-vimtex coc-explorer

# Look and feel
apt install neofetch zsh zsh-antigen

git clone https://github.com/alexanderjeurissen/ranger_devicons ~/.config/ranger/plugins/ranger_devicons

# Utilities
apt install man-db flameshot redshift mpv sxiv

# System tools 
apt install htop ssh

# Multimedia
apt install firefox-esr telegram-desktop 

# Virtualisation (soon)

# Security 
apt install ufw 
ufw enable 

# dotfiles
git clone --depth=1 https://github.com/t1mron/dotfiles_devuan $HOME/git/dotfiles_devuan
cp -r $HOME/git/dotfiles_devuan/. $HOME/ && rm -rf $HOME/root .git LICENSE README.md readme.txt
sudo cp -r $HOME/git/dotfiles_devuan/root/. /

