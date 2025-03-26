##########################################
## Proxmox configuration
##########################################
variable "proxmox_api_url" {
  type        = string
  description = "The URL of the Proxmox VE API (e.g., 'https://proxmox-host:8006/')"
}

variable "proxmox_api_username" {
  type        = string
  sensitive   = true
  description = "The username for authenticating with the Proxmox VE API"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "The API token for authenticating with the Proxmox VE API"
}


##########################################
## K3S Compute configuration
##########################################
variable "hosts" {
  type = map(object({
    host       = string
    vm_name    = string
    ip_address = string
  }))
  default = {
    control-1 = {
      host       = "host1"
      vm_name    = "control-1.k3s"
      ip_address = "192.168.1.10/24"
    }
    worker-1 = {
      host       = "host2"
      vm_name    = "worker-1.k3s"
      ip_address = "192.168.1.110/24"
    }
    worker-2 = {
      host       = "host3"
      vm_name    = "worker-2.k3s"
      ip_address = "192.168.1.120/24"
    }
  }
  description = "Map of k3s nodes with their Proxmox host, VM name, and IP address (with CIDR notation)"
}


##########################################
## K3S nodes related vars
##########################################
variable "ubuntu_image_url" {
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  description = "URL for downloading the Ubuntu 24.04 Noble cloud image used for k3s VM creation"
}

variable "k3s_node_username" {
  type        = string
  sensitive   = true
  default     = "ubuntu"
  description = "Username for SSH access to k3s nodes (default is 'ubuntu' for Ubuntu cloud images)"
}

variable "k3s_node_password" {
  type        = string
  sensitive   = true
  description = "Password for the k3s node user account (used if SSH key auth fails)"
}

variable "network_gateway" {
  type        = string
  description = "IP address of the network gateway for the k3s nodes (e.g., '192.168.1.1')"
}

variable "k3s_node_storage_size" {
  type        = string
  description = "Size of the VM disk in gigabytes for k3s nodes"
}

variable "k3s_token" {
  type        = string
  sensitive   = true
  description = "Shared secret token used to authenticate k3s nodes to the cluster"
}


##########################################
## Flux related vars
##########################################
variable "github_owner" {
  type        = string
  description = "GitHub username or organization"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub Personal Access Token with repo scope"
}

variable "github_branch" {
  type        = string
  default     = "main"
  description = "GitHub branch to be used by flux"
}
