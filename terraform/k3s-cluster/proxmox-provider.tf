provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = true
  ssh {
    agent    = true
    username = "root"
    # TODO: Arrange dedicated user instead of root
  }
}
