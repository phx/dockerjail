#!/bin/bash

show_help() {
echo -e '
Usage: ./install.sh <[help | interactive | remove]>
--help 		| help 		| -h	Shows this help message.
--interactive	| interactive		Allows you to set passwords (instead of random).
--remove	| remove		Complete rollback of all changes made by install.sh.
'
}

if [[ $1 = -h ]]; then
  show_help && exit
elif [[ -n $(echo $* | grep help) ]]; then
  show_help && exit
fi

if [[ -n $(echo $* | grep remove) ]]; then
  sudo iptables-restore 2>/dev/null < /etc/iptables/iptables.beforedockerjail.rules
  sudo rm -vf /etc/iptables/dockerjail.rules
  sudo rm -vf /etc/iptables/iptables.beforedockerjail.rules
  sudo rm -vf /usr/local/bin/dockerjailrules
  sudo rm -vf id_rsa id_rsa.pub
  sudo mv -v /lib/systemd/system/docker.service.bak /lib/systemd/system/docker.service
  sudo systemctl daemon-reload
  sudo systemctl restart docker
  sudo docker stop jail 2>/dev/null
  sudo docker rm jail 2>/dev/null
  sudo docker rmi jail 2>/dev/null
  ssh-keygen -f ~/.ssh/known_hosts -R [localhost]:2222 2>/dev/null
  ssh-keygen -f ~/.ssh/known_hosts -R [127.0.0.1]:2222 2>/dev/null
  # sudo systemctl restart networking
  echo 'Removed.'
  exit
fi

# Generate SSH Keypair and set up iptables:
ssh-keygen -f ~/.ssh/known_hosts -R [localhost]:2222 2>/dev/null
ssh-keygen -f ~/.ssh/known_hosts -R [127.0.0.1]:2222 2>/dev/null
ssh-keygen -q -f ./id_rsa -N '' -t rsa -b 2048
chmod 600 id_rsa.pub
chmod 600 id_rsa

# Configure iptables to act right:
sudo iptables-save | sudo tee "/etc/iptables/iptables.beforedockerjail.rules" > /dev/null 2>&1
sudo iptables -w -A INPUT -i docker0 -p tcp --dport 2222 -j ACCEPT
sudo iptables -w -I FORWARD -i docker0 -d 192.168.1.0/24 -j REJECT
sudo iptables-save | sudo tee /etc/iptables/dockerjail.rules > /dev/null 2>&1
echo -e '#!/bin/bash\n\nsudo /sbin/iptables-restore < /etc/iptables/dockerjail.rules' | sudo tee /usr/local/bin/dockerjailrules > /dev/null 2>&1
sudo chmod +x /usr/local/bin/dockerjailrules
sudo cp -pv /lib/systemd/system/docker.service /lib/systemd/system/docker.service.bak
sudo sed -i 's@containerd.sock@containerd.sock\nExecStartPost=/usr/local/bin/dockerjailrules@' /lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl restart docker

# Build Docker Image
if [[ -z $ROOTPASS ]]; then
  if [[ -n $(echo $* | grep interactive) ]]; then
    read -p 'Enter new root password for container: ' ROOTPASS
  else
    ROOTPASS="$(</dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c64; echo)"
  fi
fi
if [[ -z $USERPASS ]]; then
  if [[ -n $(echo $* | grep interactive) ]]; then
    read -p 'Enter new password for new alpine user: ' USERPASS
  else
    USERPASS="$(</dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c64; echo)"
  fi
fi
echo "root:${ROOTPASS}" > rootpasswd
echo "alpine:${USERPASS}" > passwd
sudo docker stop jail 2>/dev/null
sudo docker rm jail 2>/dev/null
sudo docker rmi jail 2>/dev/null
sudo docker build -t jail .
rm -f passwd rootpasswd
echo -e '\nRunning container:'
sudo docker run --restart=always -dp 2222:2222 --name jail jail
echo 'Restarting docker...'
sudo systemctl restart docker
if [[ $? -ne 0 ]]; then
  echo Error.
  exit
fi
sudo /usr/local/bin/dockerjailrules
sudo docker ps -a | grep jail
echo -e "\nExec into the container: docker exec -it jail /bin/sh"
echo -e "SSH into the container from the host: ssh -i id_rsa -p 2222 alpine@localhost"
echo -e "Note: The container all local network access to this container is REJECTED,"
echo -e "but if you NAT to port 2222 on this host, you will be able to access via the following command:"
echo -e "'ssh -i id_rsa -p [port] alpine@[external ip]'"
echo -e "\nIf you need to restore you previous iptables rules run 'sudo iptables-restore < /etc/iptables/iptables.beforedockerjail.rules'"
echo -e "To completely uninstall, just run './install.sh --remove'."
