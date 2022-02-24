#!/usr/bin/env bash 

#访问域名
DOMAIN='${ip}'
#数据库root密码
DB_ROOT_PW='${adminpassword}'
#数据库名
DB_USER='ncdb'
#数据库密码
DB_USER_PASS='${adminpassword}'
#nextcloud管理员
NC_ADMIN='admin'
#nextcloud密码
NC_PASS='${adminpassword}'

###########################################################################
# FUNCTIONS
###########################################################################
checkroot()
{
  if [[ $EUID != 0 ]]; then
    echo "Must be root to run this script!"
    sleep 2
    exit 1
  fi
}
check_os()
{
	if [[ $OSTYPE != linux-gnu ]]; then
	  echo "Script not compatible with your Operating system!"
	  sleep 2
	  exit 2
	fi
}
check_args()
{
  if [[ $DOMAIN = '' ]]; then
    DOMAIN=$(hostname -f)
    echo "--Nextcloud Auto Install Script--">>POST_INSTALL_NOTES.txt
    echo "Nextcloud Domain: $DOMAIN">>POST_INSTALL_NOTES.txt
  fi
  if [[ $DB_ROOT_PW = '' ]]; then
    DB_ROOT_PW=$(openssl rand -base64 32)
    echo "DB Root User Password: $DB_ROOT_PW">>POST_INSTALL_NOTES.txt
  fi
  if [[ $DB_USER = '' ]]; then
    DB_USER=nextcloud_user
    echo "Nextcloud Database User Name: $DB_USER">>POST_INSTALL_NOTES.txt
  fi
  if [[ $DB_USER_PASS = '' ]]; then
    DB_USER_PASS=$(openssl rand -base64 20)
    echo "$DB_USER Password: $DB_USER_PASS">>POST_INSTALL_NOTES.txt
  fi
}

###########################################################################
# SCRIPT
###########################################################################
checkroot

check_os

check_args

apt update && apt upgrade -y

apt install apache2 apache2-utils -y

systemctl start apache2 && systemctl enable apache2

echo "ServerName localhost">>/etc/apache2/conf-available/servername.conf

a2enconf servername.conf

systemctl reload apache2

apt install mariadb-server mariadb-client -y

systemctl start mariadb && systemctl enable mariadb

mysql << BASH_QUERY
SET PASSWORD FOR root@localhost = PASSWORD('$DB_ROOT_PW');
FLUSH PRIVILEGES;
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_USER_PASS';
CREATE DATABASE nextcloud;
GRANT ALL PRIVILEGES ON nextcloud.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
BASH_QUERY

apt install php7.4-{mysql,cli,intl,bcmath,gmp,imagick,common,json,opcache,readline,mbstring,zip,dom,xml,gd,curl} php-common libapache2-mod-php7.4 -y

a2dismod php7.4

apt install php7.4-fpm -y

a2enmod proxy_fcgi setenvif

a2enconf php7.4-fpm

systemctl restart apache2

wget https://download.nextcloud.com/server/releases/nextcloud-23.0.0.zip

apt install unzip -y

unzip nextcloud-**.*.*.zip -d /var/www/

chown www-data:www-data /var/www -R

cat << _EOF_ >> /etc/apache2/sites-available/nextcloud.conf
<VirtualHost *:80>
        DocumentRoot "/var/www/nextcloud"
        ServerName $DOMAIN
        ErrorLog $${APACHE_LOG_DIR}/nextcloud.error
        CustomLog $${APACHE_LOG_DIR}/nextcloud.access combined
        <Directory /var/www/nextcloud/>
            Require all granted
            Options FollowSymlinks MultiViews
            AllowOverride All
           <IfModule mod_dav.c>
               Dav off
           </IfModule>
        SetEnv HOME /var/www/nextcloud
        SetEnv HTTP_HOME /var/www/nextcloud
        Satisfy Any
       </Directory>
</VirtualHost>
_EOF_

a2ensite nextcloud.conf

a2enmod rewrite headers env dir mime setenvif ssl

systemctl restart apache2

#apt install certbot python3-certbot-apache -y
#let's encrypt
#certbot --apache --agree-tos --redirect --staple-ocsp --email admin@"$DOMAIN" -d "$DOMAIN"

sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/7.4/apache2/php.ini

sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/7.4/fpm/php.ini

systemctl reload apache2

apt install redis-server -y

systemctl start redis-server && systemctl enable redis-server

apt install php-redis -y

phpenmod redis

systemctl reload apache2

sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 1024M/g' /etc/php/7.4/fpm/php.ini

systemctl restart apache2 php7.4-fpm
###########################################################################
#初始化nextcloud
###########################################################################
cd /var/www/nextcloud

sudo -u www-data php occ  maintenance:install --database \
"mysql" --database-name "$DB_USER"  --database-user "root" --database-pass \
"$DB_ROOT_PW" --admin-user "$NC_ADMIN" --admin-pass "$NC_PASS"
#配置OSS作为默认主存储
###########################################################################
sed -i 's/);//g' /var/www/nextcloud/config/config.php
cat << _EOF_ >> /var/www/nextcloud/config/config.php
'objectstore' => [
        'class' => '\\OC\\Files\\ObjectStore\\S3',
        'arguments' => [
                'bucket' => '${ossbucket}', //存储桶名称
                'autocreate' => false,
                'key'    => '${ak}', //AK
                'secret' => '${secret}', //SK
                'hostname' => '${endpoint}', //输入对应的Endpoint
                'port' => "",
                'use_ssl' => false,
                'region' => '${endpoint}', //输入对应的Endpoint
                // required for some non Amazon S3 implementations
                'use_path_style'=>false
        ],
],
);
_EOF_
#######、####################################################################
#添加访问域名安全列表
###########################################################################
cd /var/www/nextcloud
sudo -u www-data php occ config:system:set trusted_domains 1 --value="$DOMAIN"
sudo -u www-data php occ app:enable files_external

