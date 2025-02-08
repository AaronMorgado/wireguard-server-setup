# READ ME
I created this to automate the process of creating a wireguard server on an ec2 instance in aws.

HOW TO USE:
1. Launch ec2 instance
2. Ensure elastic ip is assigned so you dont have a new public ip every launch (ignore this step if you are never going to shut down your instance)
3. connect to instance via ssh
4. git clone "https://github.com/AaronMorgado/wireguard-server-setup.git"
5. cd /wireguard-server-setup
6. chmod +x wireguard_setup.sh
7. sudo ./wireguard_setup.sh
8. enter public IP (get this form the aws instance console or by doing "ip a" prior to running script)
9. enter network interface (normally enX0)
10. done.

Executive summary:
The wireguard_setup.sh file creates a basic configuration for wireguard server and generates 1 client configuration to be used with whatever device you choose.

How it works:
1. installs wireguard
2. creates wireguard server pub/priv keys in /etc/wireguard/
3. creates servcer config file with default interface at /etc/wireguard/wg0.conf
4. creates a client pub/priv key pair in /etc/wireguard
5. creates a client config at /etc/wireguard/client1.conf
6. adds client to server config
7. enables wireguard service and sets it to start on instance startup
8. generates qr code in command line interface for client config

hope this helps.

- Aaron
