# AWS Ec2 Ubuntu Automated Wireguard Server Setup
Executive summary: I created this to automate the process of creating a wireguard server on an ec2 instance in aws.

The wireguard_setup.sh file creates a basic configuration for wireguard server and generates 1 client configuration to be used with whatever device you choose.

HOW TO USE:
1. Launch ec2 instance
2. Ensure elastic ip is assigned so you dont have a new public ip every launch (ignore this step if you are never going to shut down your instance)
   - if you have elastic IP you can edit the script to have the elastic IP and then use it as user-data when launching the ec2 instance to speedup      setup time.
4. connect to instance via instance connect or ssh
5. git clone "https://github.com/AaronMorgado/wireguard-server-setup.git"
6. cd /wireguard-server-setup
7. chmod +x wireguard_setup.sh
8. sudo ./wireguard_setup.sh
9. enter elastic IP (get this form the aws instance console or by doing "ip a" prior to running script)
10. enter network interface (normally enX0)
11. done.
12. verify with "sudo systemctl status wg-quick@wg0.service" (should be all green)

SETTING UP CLIENT:
1. cat out your client1.conf file in /etc/wireguard/client1.conf
2. use all the info on here to setup a wireguard client config file
3. click start and connect
4. verify in your ec2 instance with sudo wg show (will show the handshake and the download/upload speed the client is getting)

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
