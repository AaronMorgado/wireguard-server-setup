# READ ME
I created this to automate the process of creating a wireguard server on an ec2 instance in aws.

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
