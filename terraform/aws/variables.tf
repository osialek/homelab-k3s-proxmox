variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Environment = "homelab"
    Project     = "k3s-cluster"
  }
}
