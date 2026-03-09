#!/bin/bash
# HYZEX SSH Tunnel Manager v2
# Auto-restart tunnels, list, delete, and run in background

TUNNEL_DIR="$HOME/.hyzex_tunnels"
mkdir -p "$TUNNEL_DIR"

PROXY="178.239.114.245"
ALLOWED_PORTS_START=30000
ALLOWED_PORTS_END=31000
PROXY_USER="tcp-proxy"

# Function: Start a tunnel
start_tunnel() {
    read -p "Public Port ($ALLOWED_PORTS_START-$ALLOWED_PORTS_END): " PUBLIC_PORT
    read -p "Local Port (example 22): " LOCAL_PORT

    if [[ $PUBLIC_PORT -lt $ALLOWED_PORTS_START || $PUBLIC_PORT -gt $ALLOWED_PORTS_END ]]; then
        echo "Port out of allowed range!"
        return
    fi

    TUNNEL_FILE="$TUNNEL_DIR/$PUBLIC_PORT.pid"

    # Start tunnel in background with autossh for auto-reconnect
    nohup autossh -M 0 -o "ServerAliveInterval=60" -o "ServerAliveCountMax=3" \
        -N -R "$PUBLIC_PORT:localhost:$LOCAL_PORT" "$PROXY_USER@$PROXY" > "$TUNNEL_DIR/$PUBLIC_PORT.log" 2>&1 &

    echo $! > "$TUNNEL_FILE"
    echo "Tunnel started on $PROXY:$PUBLIC_PORT -> localhost:$LOCAL_PORT"
}

# Function: Stop a tunnel
stop_tunnel() {
    read -p "Public Port to stop: " PUBLIC_PORT
    TUNNEL_FILE="$TUNNEL_DIR/$PUBLIC_PORT.pid"

    if [[ -f "$TUNNEL_FILE" ]]; then
        kill $(cat "$TUNNEL_FILE") && rm -f "$TUNNEL_FILE"
        echo "Tunnel on port $PUBLIC_PORT stopped."
    else
        echo "No tunnel found for port $PUBLIC_PORT"
    fi
}

# Function: Delete a tunnel (stop + remove log)
delete_tunnel() {
    read -p "Public Port to delete: " PUBLIC_PORT
    TUNNEL_FILE="$TUNNEL_DIR/$PUBLIC_PORT.pid"
    LOG_FILE="$TUNNEL_DIR/$PUBLIC_PORT.log"

    if [[ -f "$TUNNEL_FILE" ]]; then
        kill $(cat "$TUNNEL_FILE") && rm -f "$TUNNEL_FILE"
    fi

    if [[ -f "$LOG_FILE" ]]; then
        rm -f "$LOG_FILE"
    fi

    echo "Tunnel on port $PUBLIC_PORT deleted."
}

# Function: List active tunnels
list_tunnels() {
    echo "Active tunnels:"
    for pidfile in $TUNNEL_DIR/*.pid; do
        [[ -f "$pidfile" ]] || continue
        PORT=$(basename "$pidfile" .pid)
        PID=$(cat "$pidfile")
        if ps -p $PID > /dev/null; then
            echo "Port $PORT -> PID $PID (running)"
        else
            echo "Port $PORT -> not running"
        fi
    done
}

# Main menu
while true; do
    clear
    echo "================================="
    echo "      HYZEX SSH Tunnel Manager"
    echo "================================="
    echo "Proxy: $PROXY"
    echo "Allowed Ports: $ALLOWED_PORTS_START-$ALLOWED_PORTS_END"
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
        5) exit 0 ;;
        *) echo "Invalid option!" ;;
    esac
    read -p "Press ENTER to continue..."
done
