FROM alpine:latest

RUN apk add openssh && adduser -D -s /bin/ash alpine

COPY sshd_config /home/alpine/.ssh/sshd_config

COPY scripts/entrypoint.sh /home/alpine/entrypoint.sh

COPY scripts/regenerate_keys.sh /home/alpine/regenerate_keys.sh

COPY passwd /home/alpine/passwd

COPY rootpasswd /root/passwd

RUN cat /root/passwd | chpasswd &&\
    rm /root/passwd &&\
    passwd -d root &&\
    cat /home/alpine/passwd | chpasswd &&\
    rm /home/alpine/passwd &&\
    chown -R alpine:alpine /home/alpine &&\
    chmod +x /home/alpine/entrypoint.sh &&\
    echo "export VISIBLE=now" >> /etc/profile &&\
    ssh-keygen -A &&\
    chown alpine:alpine /etc/ssh/ssh_host_*

USER alpine

COPY DISCLAIMER /home/alpine/

RUN cat /home/alpine/DISCLAIMER

EXPOSE 2222

ENTRYPOINT ["/home/alpine/entrypoint.sh"]
