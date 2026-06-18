terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70"
    }
  }
}

provider "proxmox" {
  endpoint = "https://54.36.107.64:8006/"
  username = "terraform@pve"
  password = "MtpypiIves7Xn96W"
  insecure = true
}

resource "proxmox_virtual_environment_pool" "terraform_test" {
  pool_id = "terraform-test"
  comment = "Pool de test cree avec Terraform pour le projet CYNA"
}

resource "proxmox_virtual_environment_container" "ct_test" {
  description = "CT de test cree avec Terraform pour le projet CYNA"
  node_name   = "Geneve"
  vm_id       = 114

  initialization {
    hostname = "tf-test-ct"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      password = "Respons11"
    }
  }

  disk {
    datastore_id = "local"
    size         = 4
  }

  network_interface {
    name   = "eth0"
    bridge = "Admin"
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
    type             = "debian"
  }

  pool_id = "terraform-test"

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
    swap      = 512
  }

  started = true
}
