output "k3s_node_private_key" {
  value       = tls_private_key.k3s_node_key.private_key_pem
  sensitive   = true
  description = "The private SSH key (PEM format) used for accessing k3s nodes"
}

output "k3s_node_public_key" {
  value       = tls_private_key.k3s_node_key.public_key_openssh
  description = "The public SSH key (OpenSSH format) used for accessing k3s nodes"
}

output "k3s_node_private_key_path" {
  value       = local_file.k3s_node_private_key.filename
  description = "The local file path where the k3s node private key is stored"
}
