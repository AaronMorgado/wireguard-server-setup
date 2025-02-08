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
mkdir /etc/wireguard/

# Generate Private Key
sudo wg genkey | sudo tee /etc/wireguard/server_private.key || error_exit "Failed to generate server private key."
# Set Private Key Permissions
sudo chmod 600 /etc/wireguard/server_private.key || error_exit "Failed to set private key permissions."
# Generate Public Key
sudo cat /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key || error_exit "Failed to generate server public key."
# Get main network interface
read -p "Enter your main network interface (e.g., enp1s0): " INTERFACE
if [[ -z "$INTERFACE" ]]; then
    error_exit "Network interface cannot be empty."
fi

PRIVATE_KEY=$(sudo cat /etc/wireguard/server_private.key)

# Create configuration file
sudo nano /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.8.0.1/24
SaveConfig = true
PrivateKey = $PRIVATE_KEY
PostUp = ufw route allow in on wg0 out on $INTERFACE
PostUp = iptables -t nat -I POSTROUTING -o $INTERFACE -j MASQUERADE
PreDown = ufw route delete allow in on wg0 out on $INTERFACE
PreDown = iptables -t nat -D POSTROUTING -o $INTERFACE -j MASQUERADE
ListenPort = 51820
EOF

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
sudo nano /etc/wireguard/client1.conf << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.8.0.2/24
DNS = 8.8.8.8
[Peer]
PublicKey = $SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0
Endpoint = $SERVER_IP:51820
PersistentKeepalive = 15
EOF

# Add Peer to Server Config
sudo nano /etc/wireguard/wg0.conf << EOF
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.8.0.2/32
EOF

# --- Enable WireGuard Service ---
echo "Enabling WireGuard service..."
sudo systemctl start wg-quick@wg0.service || error_exit "Failed to start WireGuard service."
sudo systemctl enable wg-quick@wg0.service || error_exit "Failed to enable WireGuard service."
echo "done"
echo "Generating QR code"

# --- Generate QR config code ---
sudo apt install qrencode
qrencode -t png -o client1-qr.png -r /etc/wireguard/client1.conf
echo"done"
