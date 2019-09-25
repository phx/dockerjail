# DockerJail

This container acts as a secure jumpbox running as a non-root user.

NAT port 2222 on the host to SSH with the private key generated after running install.sh.

## Install via install.sh from master branch

1. `git clone https://github.com/phx/dockerjail.git`
2. `cd dockerjail && ./install.sh`

(sudo will be required for some commands in the script).

Container uses key-based authentication and will only have password-based SSH access to the the host with no access to the rest of the network.

## Uninstall via install.sh
1. `git clone https://github.com/phx/dockerjail.git` (if you already deleted it).
2. `cd dockerjail && ./install.sh remove`

This will perform a complete rollback of all of the changes made when running install.sh

### Host Dependencies for install.sh:
1. [Docker](https://github.com/oldjamey/dockerinstall) (easy unofficial-official install script for Ubuntu/Debian/Raspbian/Arch/Kali)
2. `/bin/bash` (not `sh`)
3. `/sbin/iptables`

If `iptables` exists on a different location on your OS, **change the path in the Dockerfile**.
I will add this to my to-do's.

### Warnings and Limitations for install.sh:
This will completely lockdown the `docker0` interface, so it is not really meant to be run alongside other containers.  If you want to customize the `iptables` rules, you can do so in the `Dockerfile` before running `install.sh` or after running `install.sh` by editing `/usr/local/bin/dockerjailrules` and restarting `docker.service`.

This script also runs under the assumption that you are on the **192.168.1.0/24** network.  If this is not the case, please modify the `iptables` rules by referring to the same steps listed above.  I have plans to build the network into the script via argument and environment variable in the future, but as of right now, it is hard-coded.

**The Docker service will be restarted during the installation process.**

#### Notes about install.sh:
You can also set the passwords of the root user and the alpine user by passing
the `$ROOTPASS` and `$USERPASS` environment variables if you do not wish them to be random.

Additionally, if you can run `./install.sh interactive` to be prompted for each password,
which will be shown in clear text.

These options are kind of pointless since the root user account is disabled and the alpine user can
only log in with an SSH key, but they are options nonetheless. 

#### Usage:
```
Usage: ./install.sh <[help | interactive | remove]>
--help          | help         | -h     Shows this help message.
--interactive   | interactive           Allows you to set passwords (instead of random).
--remove        | remove                Complete rollback of all changes made by install.sh.
```

## Non-intrusive pure Docker installation:
*Note: this is not nearly as secure, as it does require, nor implement any `iptables` rules to lockdown the container to only the host.*

*The container will have SSH access to the host, as well as the rest of the entire local network.*

*If you NAT, then this is basically the equivalent of just opening up SSH to the world, except locking it down with key-based access.*

*Not entirely insecure, yet not entirely recommended for external access from the Internet.*

*You would probably be better off running sshd with key-based access on the host and installing `fail2ban` instead.*

1. `docker run --restart=always -dp 2222:2222 lphxl/dockerjail:latest`
2. `docker exec -it dockerjail sh`
3. `/home/alpine/regnerate_keys.sh`
4. `exit`
5. `docker cp dockerjail:/home/alpine/.ssh/id_rsa dockerjail.pem && chmod 400 dockerjail.pem`

### Alternatively, you can build the image yourself by cloning the dev branch:
1. `git clone --single-branch --branch dev https://github.com/phx/dockerjail.git`
2. `cd dockerjail && docker build -t dockerjail .`
3. `docker exec -it dockerjail sh`
4. `/home/alpine/regnerate_keys.sh`
5. `exit`
6. `docker cp dockerjail:/home/alpine/.ssh/id_rsa dockerjail.pem && chmod 400 dockerjail.pem`

