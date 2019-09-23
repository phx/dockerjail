FROM alpine:latest

RUN apk add openssh && adduser -D -s /bin/ash alpine

COPY sshd_config /home/alpine/.ssh/sshd_config

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

EXPOSE 2222

ENTRYPOINT ["/home/alpine/entrypoint.sh"]
