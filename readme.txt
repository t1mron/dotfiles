# basic 
sudo apt install sysv-rc-conf network-manager iwd wget vim git ssh

# Window manager
sudo apt install bspwm sxhkd xserver-xorg-core xinit xinput x11-utils x11-xserver-utils polybar ranger rxvt-unicode rofi fonts-font-awesome fonts-hack arandr autorandr

# Laptop (soon)

# wi-fi, sound, bluetooth, vpn (soon)

# Office programs
sudo apt install texlive-full zathura

# vim plugins
sudo apt install python3-pip
pip3 install pynvim pylint

PlugInstall
CocInstall coc-vimlsp coc-python coc-sh coc-vimtex coc-explorer

# Look and feel
sudo apt install neofetch zsh zsh-antigen

git clone https://github.com/alexanderjeurissen/ranger_devicons ~/.config/ranger/plugins/ranger_devicons

# Utilities
sudo apt install timeshift man-db flameshot redshift mpv sxiv

# System tools 
sudo apt install htop 

# Multimedia
sudo pacman -S firefox-esr telegram-desktop discord

# Virtualisation (soon)

# Security 
sudo apt install ufw 
sudo ufw enable 
