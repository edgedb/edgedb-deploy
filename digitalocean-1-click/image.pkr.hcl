variable "package_version" {
  type = string
}

variable "token" {
  type      = string
  sensitive = true
  default   = env("DIGITALOCEAN_ACCESS_TOKEN")
}

source "digitalocean" "x" {
  api_token    = "${var.token}"
  image        = "ubuntu-20-04-x64"
  region       = "sfo3"
  size         = "s-1vcpu-1gb"
  ssh_username = "root"
}

build {
  source "digitalocean.x" {
    droplet_name  = "edgedb-${var.package_version}-builder-${uuidv4()}"
    snapshot_name = "edgedb-${var.package_version}"
  }

  provisioner "shell" {
    script = "setup.sh"
    environment_vars = [
      "EDGEDB_PKG=edgedb-server-${var.package_version}",
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
