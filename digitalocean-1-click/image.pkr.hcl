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
  name = "with-pg"

  source "digitalocean.x" {
    droplet_name  = "edgedb-withpg-${var.package_version}-builder-${uuidv4()}"
    snapshot_name = "edgedb-withpg-${var.package_version}"
  } 

  provisioner "shell" {
    script = "withpg.sh"
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

build {
  name = "without-pg"

  source "digitalocean.x" {
    droplet_name  = "edgedb-${var.package_version}-builder-${uuidv4()}"
    snapshot_name = "edgedb-${var.package_version}"
  }

  provisioner "shell" {
    script = "withoutpg.sh"
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
