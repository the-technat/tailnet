resource "tailscale_dns_configuration" "configuration" {
  magic_dns = true
}

locals {
  # generated in the console after magic_dns was enabled
  # cannot be changed again once magic https is enabled (see settings.tf)
  domain_name = "lamb-exponential.ts.net"
}
