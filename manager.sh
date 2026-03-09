#!/bin/bash

SERVER="178.239.114.245"
USER="tcp-proxy"
PASSWORD="0"
DATA_DIR="$HOME/.tunnel-manager"

mkdir -p "$DATA_DIR"

install_deps() {
if ! command -v autossh &> /dev/null; then
echo "Installing autossh and sshpass..."
sudo apt update
sudo apt install autossh sshpass -y
fi
}

start_tunnel() {
read -p "Public Port (30000-31000): " PUB
read -p "Local Port (example 25565): " LOCAL

echo "Starting tunnel..."

sshpass -p "$PASSWORD" autossh -M 0 -f -N \
-o StrictHostKeyChecking=no \
-R ${PUB}:localhost:${LOCAL} \
${USER}@${SERVER}

echo "$LOCAL" > "$DATA_DIR/$PUB.port"

echo ""
echo "Tunnel started!"
echo "Connect using:"
echo "$SERVER:$PUB"
}

stop_tunnel() {
read -p "Public Port to stop: " PORT

PID=$(ps aux | grep "R ${PORT}:localhost" | grep -v grep | awk '{print $2}')

if [ ! -z "$PID" ]; then
kill $PID
echo "Tunnel stopped."
else
echo "Tunnel not running."
fi
}

delete_tunnel() {
read -p "Public Port to delete: " PORT

PID=$(ps aux | grep "R ${PORT}:localhost" | grep -v grep | awk '{print $2}')

if [ ! -z "$PID" ]; then
kill $PID
fi

rm -f "$DATA_DIR/$PORT.port"

echo "Tunnel deleted."
}

list_tunnels() {

echo ""
echo "Active tunnels:"
echo "-------------------------"

if [ -z "$(ls -A $DATA_DIR 2>/dev/null)" ]; then
echo "No tunnels saved."
return
fi

for file in $DATA_DIR/*.port
do
PORT=$(basename $file .port)
LOCAL=$(cat $file)

RUNNING=$(ps aux | grep "R ${PORT}:localhost:${LOCAL}" | grep -v grep)

if [ ! -z "$RUNNING" ]; then
STATUS="RUNNING"
else
STATUS="STOPPED"
fi

echo "$SERVER:$PORT -> localhost:$LOCAL [$STATUS]"

done
}

while true
do
clear
echo "================================="
echo "      HYZEX SSH Tunnel Manager"
echo "================================="
echo "Proxy: $SERVER"
echo "Allowed Ports: 30000-31000"
echo "================================="
echo "1) Start Tunnel"
echo "2) Stop Tunnel"
echo "3) Delete Tunnel"
echo "4) List Tunnels"
echo "5) Exit"
echo "================================="

read -p "Select option: " OPTION

case $OPTION in
1) start_tunnel ;;
2) stop_tunnel ;;
3) delete_tunnel ;;
4) list_tunnels ;;
5) exit ;;
*) echo "Invalid option";;
esac

echo ""
read -p "Press ENTER to continue..."
done
