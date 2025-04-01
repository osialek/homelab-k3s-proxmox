terraform {
  backend "s3" {
    bucket       = "tf-state-homelab-767397961903"
    key          = "terraform/aws/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}
