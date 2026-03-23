#!/bin/bash

HOST="178.239.114.245"
USER="tcp-proxy"
PASS="0"
PID_FILE="tunnels.pid"

touch $PID_FILE

create_tunnel() {
    read -p "Enter remote port (20000-21000): " RPORT

    if [[ -z "$RPORT" || $RPORT -lt 20000 || $RPORT -gt 21000 ]]; then
        echo "❌ Invalid port range!"
        return
    fi

    # Check if already used
    if grep -q "^$RPORT:" $PID_FILE; then
        echo "⚠️ Port already in use!"
        return
    fi

    read -p "Enter target port (e.g. 22, 25565): " TARGET_PORT

    if [[ -z "$TARGET_PORT" ]]; then
        echo "❌ Target port cannot be empty!"
        return
    fi

    echo "🚀 Creating tunnel..."
    echo "Remote: $HOST:$RPORT → localhost:$TARGET_PORT"

    nohup sshpass -p "$PASS" ssh \
    -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    -N -R ${RPORT}:localhost:${TARGET_PORT} ${USER}@${HOST} \
    > /dev/null 2>&1 &

    PID=$!
    echo "$RPORT:$PID:$TARGET_PORT" >> $PID_FILE

    echo "✅ Tunnel started in background (PID: $PID)"
}

list_tunnels() {
    echo ""
    echo "📋 Active tunnels:"
    echo "----------------------------"

    if [[ ! -s $PID_FILE ]]; then
        echo "No tunnels found."
        return
    fi

    while IFS=: read RPORT PID TARGET_PORT
    do
        if ps -p $PID > /dev/null 2>&1; then
            echo "🟢 $RPORT → localhost:$TARGET_PORT | PID: $PID"
        else
            echo "🔴 $RPORT → localhost:$TARGET_PORT | PID: $PID (DEAD)"
        fi
    done < $PID_FILE
}

delete_tunnel() {
    read -p "Enter remote port to delete: " RPORT

    if grep -q "^$RPORT:" $PID_FILE; then
        PID=$(grep "^$RPORT:" $PID_FILE | cut -d: -f2)

        kill $PID 2>/dev/null
        sed -i "/^$RPORT:/d" $PID_FILE

        echo "❌ Tunnel on port $RPORT stopped."
    else
        echo "⚠️ Tunnel not found."
    fi
}

kill_all() {
    echo "🔥 Stopping all tunnels..."

    while IFS=: read RPORT PID TARGET_PORT
    do
        kill $PID 2>/dev/null
    done < $PID_FILE

    > $PID_FILE
    echo "✅ All tunnels stopped."
}

menu() {
    while true
    do
        echo ""
        echo "=================================="
        echo "   🚀 PORT FORWARD MANAGER"
        echo "=================================="
        echo "1. Create Tunnel"
        echo "2. List Tunnels"
        echo "3. Delete Tunnel"
        echo "4. Kill All Tunnels"
        echo "5. Exit"
        echo "=================================="

        read -p "Choose option: " CHOICE

        case $CHOICE in
            1) create_tunnel ;;
            2) list_tunnels ;;
            3) delete_tunnel ;;
            4) kill_all ;;
            5) exit 0 ;;
            *) echo "❌ Invalid option!" ;;
        esac
    done
}

menu
