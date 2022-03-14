# DigitalOcean 1-Click Image

1. install [packer](https://www.packer.io/downloads)
2. build an image:

```bash
export DIGITALOCEAN_ACCESS_TOKEN=<your-token-here>
packer build -var 'package_version=1' image.pkr.hcl
```
