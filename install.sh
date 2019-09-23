#!/bin/bash

timestamp="$(date +%Y%m%d.%I%M%S)"

# Generate SSH Keypair and set up iptables:
ssh-keygen -f ~/.ssh/known_hosts -R [localhost]:2222
ssh-keygen -f ~/.ssh/known_hosts -R [127.0.0.1]:2222
ssh-keygen -q -f ./id_rsa -N '' -t rsa -b 2048
chmod 600 id_rsa.pub
chmod 600 id_rsa
sudo iptables-save > "/etc/iptables/iptables.${timestamp}.rules"
echo 'sudo iptables -A INPUT -i docker0 -p tcp --dport 22 -j ACCEPT' | sudo tee /etc/iptables/dockerchroot.rules
echo 'sudo iptables -I FORWARD -i docker0 -d 192.168.1.0/24 -j REJECT' | sudo tee -a /etc/iptables/dockerchroot.rules
cat /etc/iptables/dockerchroot.rules | sudo iptables-restore
echo 'If you need to restore you previous iptables rules,'
echo "run 'sudo iptables-restore < /etc/iptables/iptables.${timestamp}.rules'"

# Build Docker Image
read -p 'Enter new root password for container: ' rootpasswd
read -p 'Enter new password for new alpine user: ' alpinepasswd
echo "root:${rootpasswd}" > rootpasswd
echo "alpine:${alpinepasswd}" > passwd
docker stop chroot 2>/dev/null
docker rm chroot 2>/dev/null
docker rmi chroot 2>/dev/null
docker build -t chroot .
echo
echo 'Running container:'
docker run -dp 127.0.0.1:2222:2222 --name chroot chroot
docker ps -a | grep chroot
echo
echo "Adding container's public key to ${HOME}/.ssh/authorized_keys..."
docker cp chroot:/home/alpine/.ssh/id_rsa.pub chroot.rsa.pub
cat chroot.rsa.pub | tee -a "${HOME}/.ssh/authorized_keys"
chmod 700 "${HOME}/.ssh"
chmod 600 "${HOME}/.ssh/authorized_keys"
rm -v chroot.rsa.pub
echo -e '\nDone.'
