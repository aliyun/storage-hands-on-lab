#! /bin/sh
echo "start" >> /home/init.log
apt update
apt-get install s3fs -y
echo "s3fs installed" >> /home/init.log
echo "${ak}:${secret}" > /home/.passwd-s3fs 
chmod 600 /home/.passwd-s3fs
echo "password created" >> /home/init.log
mkdir /tmp/s3fs
echo "mounting" >> /home/init.log
s3fs ${ossbucket}  /tmp/s3fs -o passwd_file=/home/.passwd-s3fs -o url=http://${endpoint} -o dbglevel=info -f -o curldbg -o nonempty