#DockerJail

This container acts as a secure jumpbox running as a non-root user.

NAT port 2222 on the host to SSH with the private key generated after running install.sh.

Modify install.sh with the correct CIDR range if you are not using 192.168.1.0/24.

Container uses key-based authentication and will only have password-based SSH access to the the host with no access to the rest of the network.



Run ./install.sh.

Sudo will be required for some commands.

Adding additional users is outside the scope of this project, but can easily be achieved by reading through and modifying the Dockerfile.

To uninstall, just run './install.sh --remove'.

Warning: This will lock down the docker0 interface, so if you are running additional containers that will need access to 192.168.1.0/24, you will need to update the iptables rules.
