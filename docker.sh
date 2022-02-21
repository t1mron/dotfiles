sudo apt update && sudo apt upgrade -y
sudo apt install docker.io docker-compose
sudo usermod -aG docker $USER
newgrp docker
mkdir -p $HOME/wireguard/config

IP=$(curl ifconfig.me)
MAIL=""
cat << EOF > $HOME/wireguard/docker-compose.yml
version: "2.1"
services:
  wireguard:
    image: ghcr.io/linuxserver/wireguard
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - SERVERURL=$IP #optional
      - SERVERPORT=51820 #optional
      - PEERS=4 #optional
      - PEERDNS=auto #optional
      - INTERNAL_SUBNET=10.13.13.0 #optional
      - ALLOWEDIPS=0.0.0.0/0 #optional
    volumes:
      - $HOME/wireguard/config:/config
      - /lib/modules:/lib/modules
    ports:
      - 51820:51820/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
EOF

cd $HOME/wireguard && docker-compose up -d
