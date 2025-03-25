resource "proxmox_virtual_environment_download_file" "release_current_ubuntu_24_04_noble_amd64_img" {
  for_each     = { for k, v in var.hosts : v.host => v }
  content_type = "iso"
  datastore_id = "local"
  file_name    = "noble-server-cloudimg-amd64.img"
  node_name    = each.value.host
  url          = var.ubuntu_image_url
}

resource "proxmox_virtual_environment_vm" "k3s_node" {
  for_each    = var.hosts
  name        = each.value.vm_name
  description = "Ubuntu VM for general purpose"
  tags        = ["terraform", "ubuntu"]
  node_name   = each.value.host

  stop_on_destroy = true

  operating_system {
    type = "l26"
  }

  cpu {
    cores = 6
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 15360
    floating  = 15360 # set equal to dedicated to enable ballooning
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.k3s_node_storage_size
    file_id      = proxmox_virtual_environment_download_file.release_current_ubuntu_24_04_noble_amd64_img[each.value.host].id
    interface    = "scsi0"
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = each.value.ip_address
        gateway = var.network_gateway
      }
    }
    user_account {
      keys     = [trimspace(tls_private_key.k3s_node_key.public_key_openssh)]
      password = var.k3s_node_password
      username = var.k3s_node_username
    }
  }

  # Ignore changes to disk file_id
  lifecycle {
    ignore_changes = [
      disk[0].file_id
    ]
  }
}

resource "tls_private_key" "k3s_node_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "k3s_node_private_key" {
  content         = tls_private_key.k3s_node_key.private_key_pem
  filename        = "${path.module}/k3s_node_key.pem"
  file_permission = "0600"
}
