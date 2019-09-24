FROM alpine:latest

RUN apk add openssh && adduser -D -s /bin/ash alpine

COPY sshd_config /home/alpine/.ssh/sshd_config

COPY id_rsa /home/alpine/

ADD id_rsa.pub /home/alpine/.ssh/authorized_keys

COPY entrypoint.sh /home/alpine/entrypoint.sh

COPY passwd /home/alpine/passwd

COPY rootpasswd /root/passwd

RUN cat /root/passwd | chpasswd &&\
    rm /root/passwd &&\
    passwd -d root &&\
    cat /home/alpine/passwd | chpasswd &&\
    rm /home/alpine/passwd &&\
    chown -R alpine:alpine /home/alpine &&\
    chmod +x /home/alpine/entrypoint.sh &&\
    chmod 700 /home/alpine/.ssh &&\
    chmod 600 /home/alpine/.ssh/authorized_keys &&\ 
    echo "export VISIBLE=now" >> /etc/profile &&\
    ssh-keygen -A &&\
    chown alpine:alpine /etc/ssh/ssh_host_*

USER alpine

RUN ssh-keygen -q -f /home/alpine/.ssh/id_rsa -N '' -t rsa -b 2048 &&\
    chmod 600 /home/alpine/.ssh/id_rsa.pub &&\
    chmod 400 /home/alpine/.ssh/id_rsa

RUN echo -e "\n \
To test this image, first run the container with \
'docker run --rmdp 2222:2222 --name jail oldjamey/dockerjail:latest', \
and pull the private key from the container using \
'docker cp jail:/home/alpine/id_rsa dockerjail.pem'. \
Run 'chmod 600 dockerjail.pem' to make sure permissions are secure (enough). \
Then 'ssh -i dockerjail.pem -p 2222 alpine@localhost' to SSH into the container. \
\
Pulling this public Docker image is pretty insecure because you will be sharing a \
private key with anyone running the same version, so your container at least could get \
pretty easily compromised. \
\
Without the iptables implementation on the host, this is mainly just an insecure container \
running sshd as a non-root user, and it is at the mercy of the host's password weakness. \
\
For this reason, I would urge you to clone the GitHub repo from https://github.com/lphxl/dockerjail.git \
and build the container yourself by running the install.sh script, which has a lot of bells and whistles \
to secure your container and lock it down to only be able to access the host. \
\
Not to mention having your own privately-generated ssh keypair ;)\n" 1>&2

EXPOSE 2222

ENTRYPOINT ["/home/alpine/entrypoint.sh"]
