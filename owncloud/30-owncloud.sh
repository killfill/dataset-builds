log "creating owncloud database"

svcadm enable percona-server:default

log "waiting for mysql"

MYSQL_TIMEOUT=60
while [[ ! -e /tmp/mysql.sock ]]; do
  : ${MYCOUNT:=0}
  sleep 1
  ((MYCOUNT=MYCOUNT+1))
  if [[ $MYCOUNT -eq $MYSQL_TIMEOUT ]]; then
    log "ERROR Could not talk to MySQL after ${MYSQL_TIMEOUT} seconds"
    ERROR=yes
    break 1
  fi
done
[[ -n "${ERROR}" ]] && exit 31

log "(it took ${MYCOUNT} seconds to start properly)"

sleep 1

mysql -u root << EOF
create database IF NOT EXISTS owncloud character set utf8;
grant all privileges on owncloud.* to owncloud@localhost identified by 'owncloud';
EOF

