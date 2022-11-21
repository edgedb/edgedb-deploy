# DigitalOcean 1-Click Image

## To build an image

1. install [packer](https://www.packer.io/downloads)
2. build an image:

```bash
export DIGITALOCEAN_ACCESS_TOKEN=<your-token-here>
packer build -var 'package_version=2' image.pkr.hcl
```

Documentation on building images for DigitalOcean Marketplace is
[here](https://github.com/digitalocean/marketplace-partners)


## To update the DigitalOcean's Marketplace image

0. build an image
1. find the image on [this page](https://cloud.digitalocean.com/images/snapshots/droplets)
2. add the image to all regions
3. select `Update a 1-click App` from the `More` drop down.
