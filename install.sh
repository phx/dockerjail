#!/bin/bash

timestamp="$(date +%Y%m%d.%I%M%S)"

# Generate SSH Keypair and set up iptables:
ssh-keygen -f ~/.ssh/known_hosts -R [localhost]:2222
ssh-keygen -f ~/.ssh/known_hosts -R [127.0.0.1]:2222
ssh-keygen -q -f ./id_rsa -N '' -t rsa -b 2048
chmod 600 id_rsa.pub
chmod 600 id_rsa
sudo iptables-save | sudo tee "/etc/iptables/iptables.${timestamp}.rules" > /dev/null 2>&1
sudo iptables -A INPUT -i docker0 -p tcp --dport 22 -j ACCEPT
sudo iptables -I FORWARD -i docker0 -d 192.168.1.0/24 -j REJECT
sudo iptables-save | sudo tee /etc/iptables/dockerjail.rules > /dev/null 2>&1
sudo sed -i 's@exit 0@/sbin/iptables-restore < /etc/iptables/dockerjail.rules\n\nexit 0@g' /etc/rc.local
echo -e '\nIf you need to restore you previous iptables rules,'
echo -e "run 'sudo iptables-restore < /etc/iptables/iptables.${timestamp}.rules'"
echo -e 'You will also want to remove the line from /etc/rc.local\n'

# Build Docker Image
read -p 'Enter new root password for container: ' rootpasswd
read -p 'Enter new password for new alpine user: ' alpinepasswd
echo "root:${rootpasswd}" > rootpasswd
echo "alpine:${alpinepasswd}" > passwd
docker stop jail 2>/dev/null
docker rm jail 2>/dev/null
docker rmi jail 2>/dev/null
docker build -t jail .
rm -f passwd rootpasswd
echo -e '\nRunning container:'
docker run --restart=always -dp 0.0.0.0:2222:2222 --name jail jail
docker ps -a | grep jail
echo -e '\nExec into the container: docker exec -it jail /bin/sh'
echo 'SSH into the container: ssh -i id_rsa -p 2222 alpine@localhost'
