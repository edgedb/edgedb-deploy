#!/usr/bin/env bash

curl https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/90-cleanup.sh | bash
rm -rf /opt/digitalocean
