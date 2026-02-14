# https://registry.terraform.io/providers/tailscale/tailscale/latest/docs
provider "tailscale" {
  oauth_client_id     = var.ts_oauth_client_id
  oauth_client_secret = var.ts_oauth_client_secret
  tailnet             = var.ts_tailnet
}
