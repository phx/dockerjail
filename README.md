# DockerJail

This container acts as a secure jumpbox running as a non-root user.

NAT port 2222 on the host to SSH with the private key generated after running install.sh.

Modify install.sh with the correct CIDR range if you are not using 192.168.1.0/24.

Container uses key-based authentication and will only have password-based SSH access to the the host with no access to the rest of the network.

## Install

1. Clone the repo
2. `cd dockerjail && ./install.sh` (sudo will be required for some commands in the script).

## Uninstall
1. Clone the repo (if you already deleted it).
2. `cd dockerjail && ./install.sh remove`
This will perform a complete rollback of all of the changes made when running install.sh

### Host Dependencies:
1. [Docker](https://github.com/oldjamey/dockerinstall) (easy unofficial-official install script for Ubuntu/Debian/Raspbian/Arch/Kali)
2. Bash (not sh)
3. iptables

### Warnings and Limitations:
This will completely lockdown the `docker0` interface, so it is not really meant to be run alongside other containers.  If you want to customize the `iptables` rules, you can do so in the `Dockerfile` before running `install.sh` or after running `install.sh` by editing `/usr/local/bin/dockerjailrules` and restarting `docker.service`.

`install.sh` also runs under the assumption that you are on the **192.168.1.0/24** network.  If this is not the case, please modify the `iptables` rules by referring to the same steps listed above.  I have plans to build the network into the script via argument and environment variable in the future, but as of right now, it is hard-coded.

#### Usage:
```
Usage: ./install.sh <[help | interactive | remove]>
--help 		    | help 		| -h	Shows this help message.
--interactive	| interactive		Allows you to set passwords (instead of random).
--remove	    | remove		    Complete rollback of all changes made by install.sh.
```

