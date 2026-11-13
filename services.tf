resource "tailscale_service" "agent" {
  name    = "svc:agent"
  comment = "opencode on the tinkering VM"
  ports   = ["tcp:443"]
}

resource "tailscale_service" "code_server" {
  name    = "svc:code-server"
  comment = "code-server on the tinkering VM"
  ports   = ["tcp:443"]
}
