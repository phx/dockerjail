#!/bin/sh

echo -e 'ssh_host key checksums:\n' &&\
old_host_checksums=`for i in /etc/ssh/ssh_host*; do echo "${i}: \`sha256sum $i\`"; done` &&\
echo "$old_host_checksums" &&\ 
echo -e '\nssh private keypair checksums:\n' &&\
old_keypair_checksums=`for i in /home/alpine/.ssh/id_rs*; do echo "${i}: \`sha256sum $i\`"; done` &&\
echo -e "$old_keypair_checksums\n" 

# regenerate keys:
rm -vf /etc/ssh/ssh_host* &&\
ssh-keygen -A &&\
ls -lha /etc/ssh/ssh_host*
exit

rm -vf /home/alpine/.ssh/id_rsa /home/alpine/.ssh/id_rsa.pub /home/alpine/.ssh/known_hosts&&\
ssh-keygen -q -f /home/alpine/.ssh/id_rsa -N '' -t rsa -b 2048 &&\
chmod 600 /home/alpine/.ssh/id_rsa.pub &&\
chmod 400 /home/alpine/.ssh/id_rsa &&\

echo -e 'ssh_host key checksums:\n' &&\
new_host_checkums=`for i in /etc/ssh/ssh_host*; do echo "${i}: \`sha256sum $i\`"; done` &&\
echo "$new_host_checksums" &&\
cat /home/alpine/.ssh/id_rsa.pub > /home/alpine/.ssh/known_hosts &&\
echo -e '\nssh private keypair checksums:\n' &&\
new_keypair_checksums=`for i in /home/alpine/.ssh/id_rs*; do echo "${i}: \`sha256sum $i\`"; done` &&\
echo -e "$new_keypair_checksums\n" &&\
chmod 700 /home/alpine/.ssh &&\
chmod 600 /home/alpine/.ssh/known_hosts &&\

echo -e 'SSH KEY OLD/NEW CHECKSUM COMPARISON:'
diff -y <(echo "$old_host_checksums") <(echo "$new_host_checksums")
diff -y <(echo "$old_keypair_checksums") <(echo "$new_keypair_checksums")

echo -e "

Your ssh host keys and private keypair have been regenerated.

Please exit this container using Ctrl-P+Q and execute the following command to retrieve
the private key that will be used for remote SSH access:

'docker cp dockerjail:/home/alpine/.ssh/id_rsa dockerjail.pem && chmod 400 dockerjail.pem'

You will can use this key to access the dockerjail on local host via the following command:

'ssh -i /path/to/dockerjail.pem -p 2222 alpine@localhost'

Once you set up a NAT from your external IP to the host running dockerjail on port 2222,
you can remotely SSH directly into the container via the following command:

'ssh -i /path/to/dockerjail.pem -p 2222 alpine@[external ip]'
(substitute 2222 with whatever external port you have NAT'd to the dockerjail host port 2222).

"

