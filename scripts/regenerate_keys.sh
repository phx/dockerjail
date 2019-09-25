#!/bin/sh

echo -e '\ncurrent /etc/ssh/* checksums:'
old_host_checksums=`for i in /etc/ssh/*; do sha256sum $i; done`
echo "$old_host_checksums"
echo -e '\ncurrent ~/.ssh/* checksums:'
old_keypair_checksums=`for i in /home/alpine/.ssh/*; do sha256sum $i; done`
echo -e "$old_keypair_checksums\n"

# regenerate keys:
rm -vf /etc/ssh/ssh_host*
echo
ssh-keygen -A
echo
rm -vf /home/alpine/.ssh/id_rsa /home/alpine/.ssh/id_rsa.pub /home/alpine/.ssh/authorized_keys
ssh-keygen -q -f /home/alpine/.ssh/id_rsa -N '' -t rsa -b 2048
chmod 600 /home/alpine/.ssh/id_rsa.pub
chmod 400 /home/alpine/.ssh/id_rsa

echo -e '\nnew /etc/ssh/* checksums:'
new_host_checksums=`for i in /etc/ssh/*; do sha256sum $i; done`
echo "$new_host_checksums"
cat /home/alpine/.ssh/id_rsa.pub > /home/alpine/.ssh/authorized_keys
echo -e '\nnew ~/.ssh/* checksums:'
new_keypair_checksums=`for i in /home/alpine/.ssh/*; do sha256sum $i; done`
echo -e "$new_keypair_checksums\n"
chmod 700 /home/alpine/.ssh
chmod 600 /home/alpine/.ssh/authorized_keys

echo 'SSH KEY OLD/NEW CHECKSUM COMPARISON:'
tmp=`mktemp -d`
echo "$old_host_checksums" > "${tmp}/oldkeys"
echo "$old_keypair_checksums" >> "${tmp}/oldkeys"
echo "$new_host_checksums" > "${tmp}/newkeys"
echo "$new_keypair_checksums" >> "${tmp}/newkeys"
diff "${tmp}/oldkeys" "${tmp}/newkeys"
rm -rf "${tmp}"

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
