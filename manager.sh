#!/bin/bash

SERVER="178.239.114.245"
USER="tcp-proxy"
PASSWORD="0"

TUNNEL_DIR="$HOME/.tunnel-manager"

mkdir -p $TUNNEL_DIR

start_tunnel() {
    read -p "Public Port (30000-31000): " PUB
    read -p "Local Port (example 25565): " LOCAL

    echo "Starting tunnel $SERVER:$PUB -> localhost:$LOCAL"

    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -N -R $PUB:localhost:$LOCAL $USER@$SERVER \
        > $TUNNEL_DIR/$PUB.log 2>&1 &

    echo $! > $TUNNEL_DIR/$PUB.pid
    echo "$LOCAL" > $TUNNEL_DIR/$PUB.port

    echo "Tunnel started!"
    echo "Connect using: $SERVER:$PUB"
}

stop_tunnel() {
    read -p "Tunnel Public Port: " PORT

    if [ -f "$TUNNEL_DIR/$PORT.pid" ]; then
        kill $(cat $TUNNEL_DIR/$PORT.pid) 2>/dev/null
        rm -f $TUNNEL_DIR/$PORT.pid
        echo "Tunnel stopped."
    else
        echo "Tunnel not found."
    fi
}

delete_tunnel() {
    read -p "Tunnel Public Port to delete: " PORT

    if [ -f "$TUNNEL_DIR/$PORT.pid" ]; then
        kill $(cat $TUNNEL_DIR/$PORT.pid) 2>/dev/null
    fi

    rm -f $TUNNEL_DIR/$PORT.pid
    rm -f $TUNNEL_DIR/$PORT.port
    rm -f $TUNNEL_DIR/$PORT.log

    echo "Tunnel deleted."
}

list_tunnels() {
    echo "Active tunnels:"
    echo "-------------------------"

    for f in $TUNNEL_DIR/*.port; do
        [ -e "$f" ] || { echo "No tunnels."; return; }

        PUB=$(basename $f .port)
        LOCAL=$(cat $f)

        echo "$SERVER:$PUB  -> localhost:$LOCAL"
    done
}

while true
do
clear
echo "================================="
echo "        SSH Tunnel Manager"
echo "================================="
echo "1) Start Tunnel"
echo "2) Stop Tunnel"
echo "3) Delete Tunnel"
echo "4) List Tunnels"
echo "5) Exit"
echo "================================="

read -p "Select option: " opt

case $opt in
1) start_tunnel ;;
2) stop_tunnel ;;
3) delete_tunnel ;;
4) list_tunnels ;;
5) exit ;;
*) echo "Invalid option" ;;
esac

read -p "Press enter to continue..."
done
