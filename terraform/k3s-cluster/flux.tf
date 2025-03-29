resource "null_resource" "flux_bootstrap" {
  # This should depend on the moment the kubeconfig is fetched locally,
  # so we have a working ~/.kube/config to talk to the cluster.
  depends_on = [null_resource.k3s_kubeconfig_fetch]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Bootstrapping Flux with GitHub..."
      # Point flux at the KUBECONFIG we just saved
      export KUBECONFIG=~/.kube/config
      
      # Now run your preferred flux bootstrap command
      flux bootstrap github \
        --owner="${var.github_owner}" \
        --repository="${var.github_repository}" \
        --branch=${var.github_branch} \
        --path=flux/clusters/homelab \
        --personal \
        --token-auth \
        --private=false
    EOT

    # Pass the sensitive token via environment variable
    environment = {
      GITHUB_TOKEN = var.github_token

    }
  }
}