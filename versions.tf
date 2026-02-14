terraform {
  backend "remote" {
    organization = "technat"

    workspaces {
      name = "tailnet"
    }
  }
  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.27.0"
    }
  }
}
