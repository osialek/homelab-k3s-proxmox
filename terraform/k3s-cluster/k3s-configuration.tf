# Install k3s server on control-1
resource "null_resource" "k3s_server_install" {
  # run only for control-1
  depends_on = [proxmox_virtual_environment_vm.k3s_node["control-1"]]

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='server --cluster-init --token ${var.k3s_token} --write-kubeconfig-mode 644 --disable=traefik --disable=servicelb' sh -s -",
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
  depends_on = [null_resource.k3s_server_install]
  for_each   = { for k, v in var.hosts : k => v if k != "control-1" }

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

# Fetch and modify kubeconfig directly to ~/.kube/config
resource "null_resource" "k3s_kubeconfig_fetch" {
  depends_on = [null_resource.k3s_server_install]
  provisioner "remote-exec" {
    inline = [
      # Wait for kubeconfig to exist, then modify and copy it
      "for i in {1..30}; do if [ -f /etc/rancher/k3s/k3s.yaml ]; then sudo sed 's|https://127.0.0.1:6443|https://${split("/", var.hosts["control-1"].ip_address)[0]}:6443|' /etc/rancher/k3s/k3s.yaml > /home/${var.k3s_node_username}/k3s.yaml && sudo chown ${var.k3s_node_username}:${var.k3s_node_username} /home/${var.k3s_node_username}/k3s.yaml && exit 0; else sleep 2; fi; done; exit 1",
    ]
    connection {
      type        = "ssh"
      user        = var.k3s_node_username
      private_key = tls_private_key.k3s_node_key.private_key_pem
      host        = split("/", var.hosts["control-1"].ip_address)[0]
    }
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Fetching kubeconfig..." && \
      mkdir -p ~/.kube && \
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local_file.k3s_node_private_key.filename} ${var.k3s_node_username}@${split("/", var.hosts["control-1"].ip_address)[0]}:/home/${var.k3s_node_username}/k3s.yaml ~/.kube/config && \
      chmod 600 ~/.kube/config && \
      echo "Kubeconfig saved to ~/.kube/config"
    EOT
  }
}
