# Install k3s server on control-1
resource "null_resource" "k3s_server_install" {
  # run only for control-1
  depends_on = [proxmox_virtual_environment_vm.k3s_node["control-1"]]

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='server --cluster-init --token ${var.k3s_token} --write-kubeconfig-mode 644' sh -s -",
      "sudo systemctl enable k3s"
    ]

    connection {
      type        = "ssh"
      user        = var.k3s_node_username
      private_key = tls_private_key.k3s_node_key.private_key_pem
      host        = split("/", var.hosts["control-1"].ip_address)[0] # strip subnet mask
    }
  }
}

# Install k3s agent on worker nodes
resource "null_resource" "k3s_worker_install" {
  # Exclude control-1
  for_each = { for k, v in var.hosts : k => v if k != "control-1" }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | K3S_URL=https://${split("/", var.hosts["control-1"].ip_address)[0]}:6443 K3S_TOKEN=${var.k3s_token} sh -s -",
      "sudo systemctl enable k3s-agent"
    ]

    connection {
      type        = "ssh"
      user        = var.k3s_node_username
      private_key = tls_private_key.k3s_node_key.private_key_pem
      host        = split("/", each.value.ip_address)[0]
    }
  }

  depends_on = [
    null_resource.k3s_server_install
  ]
}

# Custom exec to label worker nodes which are by default not labeled
resource "null_resource" "k3s_worker_label" {
  depends_on = [null_resource.k3s_worker_install]

  provisioner "remote-exec" {
    inline = [
      for k, v in var.hosts : "sudo kubectl label node ${replace(v.vm_name, ".k3s", "")} node-role.kubernetes.io/worker=true"
      if k != "control-1"
    ]

    connection {
      type        = "ssh"
      user        = var.k3s_node_username
      private_key = tls_private_key.k3s_node_key.private_key_pem
      host        = split("/", var.hosts["control-1"].ip_address)[0]
    }
  }
}
