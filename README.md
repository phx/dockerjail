#DockerJail

This container acts as a secure userland jumpbox that you can NAT to port 2222 on the host.

Modify install.sh with the correct CIDR range if you are not using 192.168.1.0/24.

Container uses key-based authentication and will only have password-based SSH access to the the host with no access to the rest of the network.



Run ./install.sh.

Sudo will be required for some commands.

Adding additional users is outside the scope of this project, but can easily be achieved by reading through and modifying the Dockerfile.
