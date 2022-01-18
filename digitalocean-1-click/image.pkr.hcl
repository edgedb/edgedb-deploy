variable "package_version" {
  type    = string
  default = "1-rc3"
}

variable "token" {
  type      = string
  sensitive = true
  default   = env("DIGITALOCEAN_ACCESS_TOKEN")
}

source "digitalocean" "x" {
  api_token     = "${var.token}"
  image         = "ubuntu-18-04-x64"
  region        = "sfo3"
  size          = "s-1vcpu-2gb"
  ssh_username  = "root"
}

build {
  source "digitalocean.x" {
    droplet_name  = "edgedb-${var.package_version}-builder-${uuidv4()}"
    snapshot_name = "edgedb-${var.package_version}"
  }

  provisioner "shell" {
    script = "setup.sh"
    environment_vars = [
      "EDGEDB_PKG=edgedb-${var.package_version}",
      "EDGEDB_SERVER_BIN=edgedb-server-${var.package_version}"
    ]
  }

  provisioner "shell" {
    scripts = [
      "cleanup.sh",
      "img_check.sh",
    ]
  }
}
