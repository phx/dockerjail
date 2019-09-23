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
sudo iptables-save | sudo tee /etc/iptables/dockerchroot.rules > /dev/null 2>&1
echo '/sbin/iptables-restore < /etc/iptables/dockerchroot.rules' | sudo tee -a /etc/rc.local 2>&1
echo -e '\nIf you need to restore you previous iptables rules,'
echo -e "run 'sudo iptables-restore < /etc/iptables/iptables.${timestamp}.rules'"
echo -e 'You will also want to remove the line from /etc/rc.local\n'

# Build Docker Image
read -p 'Enter new root password for container: ' rootpasswd
read -p 'Enter new password for new alpine user: ' alpinepasswd
echo "root:${rootpasswd}" > rootpasswd
echo "alpine:${alpinepasswd}" > passwd
docker stop chroot 2>/dev/null
docker rm chroot 2>/dev/null
docker rmi chroot 2>/dev/null
docker build -t chroot .
rm -f passwd rootpasswd
echo -e '\nRunning container:'
docker run --restart=always -dp 0.0.0.0:2222:2222 --name chroot chroot
docker ps -a | grep chroot
echo -e '\nExec into the container: docker exec -it chroot /bin/sh'
echo 'SSH into the container: ssh -i id_rsa -p 2222 alpine@localhost'
