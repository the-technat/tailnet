output "sye_auth_key" {
  value = nonsensitive(tailscale_tailnet_key.sye_fhnw.key)
}
