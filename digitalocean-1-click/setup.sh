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
	--data-dir=/var/lib/edgedb/data \
	--bootstrap-only \
	--bootstrap-command="ALTER ROLE edgedb { SET password := 'edgedbpassword' }" \
	--tls-cert-mode=generate_self_signed
EOF

# Don't include the tls certificate in the image.
rm /var/lib/edgedb/data/*.pem

mkdir -p /etc/edgedb

cat << EOF > /etc/edgedb/env
# The PostgreSQL connection string in the URI format.
#EDGEDB_SERVER_BACKEND_DSN=

# Change to strict after setting a password.
#EDGEDB_SERVER_SECURITY=insecure_dev_mode
EOF

cat << EOF > /etc/edgedb/start.sh
#!/usr/bin/env sh

set -ex

RUNSTATE_DIR="\$1"

args="--runstate-dir=\$RUNSTATE_DIR"
args="\$args --tls-cert-mode=generate_self_signed"
args="\$args --bind-address=0.0.0.0"

if [ ! -z "\$EDGEDB_SERVER_SECURITY" ]; then
	args="\$args --security=\${EDGEDB_SERVER_SECURITY}"
fi

if [ -z "\$EDGEDB_SERVER_BACKEND_DSN" ]; then
	args="\$args --data-dir=/var/lib/edgedb/data"
else
	args="\$args --postgres-dsn=\$EDGEDB_SERVER_BACKEND_DSN"
fi

/usr/bin/${EDGEDB_SERVER_BIN} \$args
EOF

chown --recursive edgedb:edgedb /etc/edgedb
chmod +x /etc/edgedb/start.sh

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
NotifyAccess=all
ExecStart=/etc/edgedb/start.sh %t/edgedb
ExecReload=/bin/kill -HUP \${MAINPID}
KillMode=mixed
TimeoutSec=0

# edit /etc/edgedb/env to configure the postgres DSN
EnvironmentFile=/etc/edgedb/env

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl enable edgedb.service
