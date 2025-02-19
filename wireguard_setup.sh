#!/bin/bash

# --- Error Handling Function ---
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# --- User Input for Server IP ---
read -p "Enter your server's public IP address: " SERVER_IP
if [[ -z "$SERVER_IP" ]]; then
  error_exit "Server IP cannot be empty."
fi

# --- Update Server ---
echo "Updating server..."
sudo apt update -y || error_exit "Failed to update server."

# --- Install WireGuard ---
echo "Installing WireGuard..."
sudo apt install wireguard -y || error_exit "Failed to install WireGuard."

# --- Configure WireGuard Server ---
echo "Configuring WireGuard server..."

# Generate Private Key
sudo wg genkey | sudo tee /etc/wireguard/server_private.key || error_exit "Failed to generate server private key."
# Set Private Key Permissions
sudo chmod 600 /etc/wireguard/server_private.key || error_exit "Failed to set private key permissions."
# Generate Public Key
sudo cat /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key || error_exit "Failed to generate server public key."

PRIVATE_KEY=$(sudo cat /etc/wireguard/server_private.key)

# Create configuration file
echo "[Interface]" | sudo tee /etc/wireguard/wg0.conf
echo "Address = 10.8.0.1/24" | sudo tee -a /etc/wireguard/wg0.conf
echo "MTU = 1420" | sudo tee -a /etc/wireguard/.conf
echo "PrivateKey = $PRIVATE_KEY" | sudo tee -a /etc/wireguard/wg0.conf
echo "PostUp = ufw route allow in on wg0 out on enX0" | sudo tee -a /etc/wireguard/wg0.conf
echo "PostUp = iptables -t nat -I POSTROUTING -o enX0 -j MASQUERADE" | sudo tee -a /etc/wireguard/wg0.conf
echo "PreDown = ufw route delete allow in on wg0 out on enX0" | sudo tee -a /etc/wireguard/wg0.conf
echo "PreDown = iptables -t nat -D POSTROUTING -o enX0 -j MASQUERADE" | sudo tee -a /etc/wireguard/wg0.conf
echo "ListenPort = 51820" | sudo tee -a /etc/wireguard/wg0.conf

# --- Configure One Client ---
echo "Configuring WireGuard client..."
# Generate Client Private Key
sudo wg genkey | sudo tee /etc/wireguard/client1_private.key || error_exit "Failed to generate client private key."
# Generate Client Public Key
sudo cat /etc/wireguard/client1_private.key | wg pubkey | sudo tee /etc/wireguard/client1_public.key || error_exit "Failed to generate client public key."
# Get Keys
CLIENT_PRIVATE_KEY=$(sudo cat /etc/wireguard/client1_private.key)
CLIENT_PUBLIC_KEY=$(sudo cat /etc/wireguard/client1_public.key)
SERVER_PUBLIC_KEY=$(sudo cat /etc/wireguard/server_public.key)

# Create Client Config File
echo "[Interface]" | sudo tee /etc/wireguard/client1.conf
echo "PrivateKey = $CLIENT_PRIVATE_KEY" | sudo tee -a /etc/wireguard/client1.conf
echo "Address = 10.8.0.2/24" | sudo tee -a /etc/wireguard/client1.conf
echo "DNS = 8.8.8.8" | sudo tee -a /etc/wireguard/client1.conf
echo "[Peer]" | sudo tee -a /etc/wireguard/client1.conf
echo "PublicKey = $SERVER_PUBLIC_KEY" | sudo tee -a /etc/wireguard/client1.conf
echo "AllowedIPs = 0.0.0.0/0, ::/0" | sudo tee -a /etc/wireguard/client1.conf
echo "Endpoint = $SERVER_IP:51820" | sudo tee -a /etc/wireguard/client1.conf
echo "PersistentKeepalive = 25" | sudo tee -a /etc/wireguard/client1.conf

# Add Peer to Server Config
echo "[Peer]" | sudo tee -a /etc/wireguard/wg0.conf
echo "PublicKey = $CLIENT_PUBLIC_KEY" | sudo tee -a /etc/wireguard/wg0.conf
echo "AllowedIPs = 10.8.0.2/32" | sudo tee -a /etc/wireguard/wg0.conf

#--- Enable Port Forwarding --- 
sudo sysctl -w net.ipv4.ip_forward=1

# --- Enable WireGuard Service ---
echo "Enabling WireGuard service..."
sudo systemctl start wg-quick@wg0.service || error_exit "Failed to start WireGuard service."
sudo systemctl enable wg-quick@wg0.service || error_exit "Failed to enable WireGuard service."
echo "done"

# --- Print QR Code for Client Configuration ---
sudo apt install qrencode -y
sudo cp /etc/wireguard/client1.conf /home/ubuntu
sudo qrencode -t ansiutf8 < /home/ubuntu/client1.conf
