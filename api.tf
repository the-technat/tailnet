resource "tailscale_tailnet_key" "sye_fhnw" {
  reusable      = true
  preauthorized = true
  expiry        = 7776000 # 90 days
  tags          = ["tag:feature-exitnode", "tag:acl-tinkering"]
  description   = "Key used for the sye module"
}
