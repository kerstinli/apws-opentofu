resource "docker_volume" "netdata_config" {
  name = var.config_volume_name
}

resource "docker_volume" "netdata_lib" {
  name = var.lib_volume_name
}

resource "docker_volume" "netdata_cache" {
  name = var.cache_volume_name
}

module "netdata_image" {
  source = "../docker_image"
  name   = var.netdata_image_name
}

resource "docker_container" "netdata" {
  image    = module.netdata_image.image_id
  name     = "netdata"
  must_run = true
  restart  = "unless-stopped"

  pid_mode     = "host"
  network_mode = "host"

  env = [
    "NETDATA_HOST_NAME=${var.host_name}",
    "NETDATA_CLAIM_TOKEN=${var.claim_token}",
    "NETDATA_CLAIM_URL=${var.claim_url}",
    "NETDATA_CLAIM_ROOMS=${var.claim_rooms}",
  ]

  capabilities {
    add = ["SYS_PTRACE", "SYS_ADMIN"]
  }

  security_opts = ["apparmor:unconfined"]

  volumes {
    volume_name    = docker_volume.netdata_config.name
    container_path = "/etc/netdata"
  }

  volumes {
    volume_name    = docker_volume.netdata_lib.name
    container_path = "/var/lib/netdata"
  }

  volumes {
    volume_name    = docker_volume.netdata_cache.name
    container_path = "/var/cache/netdata"
  }

  volumes {
    host_path      = "/etc/passwd"
    container_path = "/host/etc/passwd"
    read_only      = true
  }

  volumes {
    host_path      = "/etc/group"
    container_path = "/host/etc/group"
    read_only      = true
  }

  volumes {
    host_path      = "/etc/os-release"
    container_path = "/host/etc/os-release"
    read_only      = true
  }

  volumes {
    host_path      = "/etc/localtime"
    container_path = "/etc/localtime"
    read_only      = true
  }

  volumes {
    host_path      = "/proc"
    container_path = "/host/proc"
    read_only      = true
  }

  volumes {
    host_path      = "/sys"
    container_path = "/host/sys"
    read_only      = true
  }

  volumes {
    host_path      = "/var/log"
    container_path = "/host/var/log"
    read_only      = true
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  mounts {
    target    = "/host/root"
    source    = "/"
    type      = "bind"
    read_only = true
    bind_options {
      propagation = "rslave"
    }
  }
}
