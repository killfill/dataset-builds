#!/usr/bin/env bash

DIST=owncloud-5.0.6.tar.bz2
DEST=/data
PHPINI=/opt/local/etc/php.ini

pkgin -y in percona-server percona-client percona-xtrabackup quickbackup-percona percona-toolkit handlersocket

pkgin -y in nginx php54-gd php54-curl php54-intl php54-fpm php54-zip php54-dom php54-mbstring php54-json php54-gd php54-zlib php54-iconv php54-pdo php54-ftp
pkgin -yf in php54-mysql
if [ ! -e $DIST ]; then
  curl -O http://download.owncloud.org/community/$DIST
  tar xfj $DIST
fi

#NGINX!
if [ $(grep owncloud.key /opt/local/etc/nginx/nginx.conf | wc -l) -eq 0 ]; then
  cp nginx.conf /opt/local/etc/nginx
# #Generate SSL keys: taken from https://github.com/project-fifo/jingles/blob/test/pkg/install.sh
  export PASSPHRASE=$(head -c 128 /dev/random  | uuencode - | grep -v "^end" | tr "\n" "d")
  openssl genrsa -des3 -out owncloud.key -passout env:PASSPHRASE 2048
  SUBJ="/C=AU
ST=Victoria
O=Company
localityName=Melbourne
commonName=owncloud
organizationalUnitName=None
emailAddress=blah@blah.com"

  openssl req \
    -new \
    -batch \
    -subj "$(echo "$SUBJ" | tr "\n" "/")" \
    -key owncloud.key \
    -out owncloud.csr \
    -passin env:PASSPHRASE
  cp owncloud.key owncloud.key.org
  openssl rsa -in owncloud.key.org -out owncloud.key -passin env:PASSPHRASE
  openssl x509 -req -days 365 -in owncloud.csr -signkey owncloud.key -out owncloud.crt
  cat owncloud.key owncloud.crt > owncloud.pem
  cp owncloud.* /var/db/
fi

if [ $(grep CUSTOMIZED $PHPINI) ]; then
  echo "php already configured"
else
  sed -i.orig 's|upload_max_filesize = 2M|upload_max_filesize = 100M|g' $PHPINI
  sed -i.orig 's|post_max_size = 8M|post_max_size = 100M|g' $PHPINI

  for i in zip dom mbstring json zlib iconv pdo gd mysql curl ftp; do
    sed -i.bak -e "s|;extension=php_zip.dll|;extension=php_zip.dll\nextension=$i.so|g" $PHPINI
  done

  sed -i.bak -e 's|;extension=php_zip.dll|;extension=php_zip.dll\n;CUSTOMIZED|g' $PHPINI
fi

#Copy to dest!
if [ ! -e $DEST ]; then
  mkdir -p $DEST
	
  cp -rip owncloud $DEST/
  chown -R www:www $DEST
	patch -p0 < installation.php.patch
fi

svcadm enable percona-server
svcadm enable php54-fpm
svcadm enable nginx

echo ========================
echo Ok, finish this up!
echo    - run sm-prepare-image
echo    - cp 31-mysql.sh /var/zoneinit/includes/
echo    - cp 32-owncloud.sh /var/zoneinit/includes/
echo    - rm -rf /root/dataset-builds
echo
