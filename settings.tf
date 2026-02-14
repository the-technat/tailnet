resource "tailscale_tailnet_settings" "settings" {
  acls_externally_managed_on                  = true
  acls_external_link                          = "https://github.com/the-technat/tailnet"
  devices_approval_on                         = true
  devices_auto_updates_on                     = true
  devices_key_duration_days                   = 30
  users_approval_on                           = true
  users_role_allowed_to_join_external_tailnet = "member"
  https_enabled                               = true
}
