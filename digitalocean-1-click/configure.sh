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

mkdir -p /var/lib/edgedb/data
chown --recursive edgedb:edgedb /var/lib/edgedb

sudo -i -u edgedb bash << EOF
$EDGEDB_SERVER_BIN \
	--data-dir /var/lib/edgedb/data \
	--bootstrap-only "--bootstrap-command=ALTER ROLE edgedb { SET password := 'edgedbpassword' }" \
	--tls-cert-mode generate_self_signed
EOF

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
ExecStart=/usr/bin/${EDGEDB_SERVER_BIN} --data-dir=/var/lib/edgedb/data --runstate-dir=%t/edgedb --tls-cert-mode generate_self_signed --bind-address 0.0.0.0
ExecReload=/bin/kill -HUP \${MAINPID}
KillMode=mixed
TimeoutSec=0

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl start edgedb.service
systemctl enable edgedb.service

# Don't include the tls certificate in this image.
rm /var/lib/edgedb/data/*.pem
