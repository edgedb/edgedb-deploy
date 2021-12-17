#!/usr/bin/env bash

set -ex

curl https://packages.edgedb.com/keys/edgedb.asc \
	| sudo apt-key add -

echo deb https://packages.edgedb.com/apt $(lsb_release -cs) main \
	| sudo tee /etc/apt/sources.list.d/edgedb.list

apt-get -y update 

# Occasionally there is a race with the background updater.
while fuser --verbose /var/lib/dpkg/lock-frontend
do
	sleep 5
done
apt-get -y dist-upgrade
apt-get -y install $EDGEDB_PKG

mkdir -p /etc/edgedb

cat << EOF > /etc/edgedb/env
# The PostgreSQL connection string in the URI format.
EDGEDB_SERVER_BACKEND_DSN=

# Change to strict after setting a password.
EDGEDB_SERVER_SECURITY=insecure_dev_mode
EOF

chown --recursive edgedb:edgedb /etc/edgedb

cat << EOF > /etc/systemd/system/edgedb.service
[Unit]
Description=EdgeDB Database Service
Documentation=https://edgedb.com/
After=syslog.target
After=network.target

[Service]
Type=notify
User=edgedb
Group=edgedb
RuntimeDirectory=edgedb
ExecReload=/bin/kill -HUP \${MAINPID}
KillMode=mixed
TimeoutSec=0

# edit /etc/edgedb/env to configure the postgres DSN
EnvironmentFile=/etc/edgedb/env
ExecStart=/usr/bin/${EDGEDB_SERVER_BIN} \
	--postgres-dsn=\${EDGEDB_SERVER_BACKEND_DSN} \
	--security=\${EDGEDB_SERVER_SECURITY} \
	--runstate-dir=%t/edgedb \
	--tls-cert-mode=generate_self_signed \
	--bind-address=0.0.0.0

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl enable edgedb.service

# document setting an admin password somewhere
