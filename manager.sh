#!/usr/bin/env bash

set -e

REMOTE_USER="tcp-proxy"
REMOTE_HOST="178.239.114.245"
PASSWORD="0"

PORT_START=30000
PORT_END=31000
LOGFILE="$HOME/tunnels.list"

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

touch $LOGFILE

install_deps() {

if ! command -v autossh >/dev/null; then
echo "Installing dependencies..."
apt update -y
apt install autossh sshpass curl -y
fi

}

auto_port() {

for ((p=$PORT_START; p<=$PORT_END; p++))
do
if ! ss -tulpn | grep -q ":$p "; then
echo $p
return
fi
done

echo "none"

}

create_tunnel() {

read -p "Local port to expose: " TARGET

PORT=$(auto_port)

if [ "$PORT" = "none" ]; then
echo -e "${RED}No free ports available${NC}"
return
fi

sshpass -p "$PASSWORD" autossh \
-M 0 \
-o StrictHostKeyChecking=no \
-o ServerAliveInterval=30 \
-o ServerAliveCountMax=3 \
-N -R $PORT:localhost:$TARGET $REMOTE_USER@$REMOTE_HOST &

PID=$!

echo "$PID $PORT $TARGET" >> $LOGFILE

echo ""
echo -e "${GREEN}Tunnel started${NC}"
echo "Remote: $REMOTE_HOST:$PORT -> localhost:$TARGET"
echo ""

}

list_tunnels() {

echo ""
echo -e "${BLUE}Running Tunnels${NC}"
echo "PID | REMOTE | LOCAL"
echo "---------------------"

while read line
do
PID=$(echo $line | awk '{print $1}')
PORT=$(echo $line | awk '{print $2}')
TARGET=$(echo $line | awk '{print $3}')

if ps -p $PID >/dev/null
then
echo "$PID | $PORT | $TARGET"
fi

done < $LOGFILE

echo ""

}

stop_tunnel() {

list_tunnels
echo ""

read -p "Enter PID to stop: " PID

kill $PID 2>/dev/null
sed -i "/^$PID /d" $LOGFILE

echo -e "${RED}Tunnel stopped${NC}"

}

scan_ports() {

echo ""
echo "Free ports ($PORT_START-$PORT_END):"
echo "-----------------------"

for ((p=$PORT_START; p<=$PORT_END; p++))
do
if ! ss -tulpn | grep -q ":$p "; then
echo "$p"
fi
done

echo ""

}

menu() {

while true
do

clear

echo -e "${GREEN}"
echo "================================="
echo "        TUNNEL MANAGER"
echo "================================="
echo -e "${NC}"

echo "1) Create tunnel"
echo "2) List tunnels"
echo "3) Stop tunnel"
echo "4) Scan free ports"
echo "5) Exit"

echo ""
read -p "Select option: " opt

case $opt in

1) create_tunnel ;;
2) list_tunnels ;;
3) stop_tunnel ;;
4) scan_ports ;;
5) exit ;;

esac

read -p "Press Enter to continue..."

done

}

install_deps
menu
