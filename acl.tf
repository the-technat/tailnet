resource "tailscale_acl" "as_hujson" {
  acl = <<EOF
  {
    "tagOwners": {
      "tag:feature-exitNode":  ["autogroup:admin"], // devices with this tag are grantaed exit-node advertisement automatically
      "tag:feature-funnel":    ["autogroup:admin"], // deviecs with this tag are granted funnel permissions automatically
      "tag:acl-kvm":           ["autogroup:admin"], // tag for KVM over IP devices
      "tag:acl-tinkering":     ["autogroup:admin"], // tag for random tinkering devices
      "tag:acl-backup":        ["autogroup:admin"], // tag for backup NAS devices
      "tag:acl-k3s":           ["autogroup:admin"], // tag for servers in the k3s cluster
    },

    "autoApprovers": {
      "routes": {
        "192.168.0.0/16":    ["tag:acl-backup"], // one backup NAS uses this
        "192.168.250.0/24": ["tag:acl-kvm"], // one KVM device uses this
        "10.42.0.0/16":      ["tag:acl-k3s"], // default k3s podCIDR
        "2001:cafe:42::/56": ["tag:acl-k3s"], // default k3s podCIDR
      },
      "exitNode": ["tag:feature-exitNode"], // auto-approve exit-nodes that have the tag
    },

    "nodeAttrs": [
      {
        "target": ["tag:feature-funnel"],
        "attr":   ["funnel"], // grant funnel to devices with this tag
      },
      {
        "target": ["technat@technat.ch"], // my private devices can funnel automatically
        "attr":   ["funnel"],
      },
      {
        "target": ["technat@technat.ch"], // my private devices are allowed to use the mullvad addon
        "attr":   ["mullvad"],
      },
    ],

    "grants": [
      // Allow to internet in any case
      {
        "src": ["autogroup:member"],
        "dst": ["autogroup:internet"],
        "ip":  ["*"],
      },

      // Everyone can communicate with it's own devices
      {
        "src": ["autogroup:member"],
        "dst": ["autogroup:self"],
        "ip":  ["*"],
      },

      // Admins are allowed to access KVM devices and their nets
      {
        "src": ["autogroup:admin"],
        "dst": ["tag:acl-kvm", "192.168.250.0/24"],
        "ip":  ["*"],
      },

      // Backup Devices are only allowed from themself and admins
      {
        "src": ["autogroup:admin"],
        "dst": ["tag:acl-backup", "192.168.1.0/24"],
        "ip":  ["80"],
      },
      {
        "src": ["autogroup:admin"],
        "dst": ["tag:acl-backup", "192.168.1.0/24"],
        "ip":  ["443"],
      },
      {
        "src": ["autogroup:admin"],
        "dst": ["tag:acl-backup", "192.168.1.0/24"],
        "ip":  ["5000"],
      },
      {
        "src": ["autogroup:admin"],
        "dst": ["tag:acl-backup", "192.168.1.0/24"],
        "ip":  ["5001"],
      },

      {
        "src": ["autogroup:admin"],
        "dst": ["tag:acl-backup", "192.168.1.0/24"],
        "ip":  ["22"],
      },
      {
        "src": ["tag:acl-backup"],
        "dst": ["tag:acl-backup"],
        "ip":  ["*"],
      },

      // Admins can access the k3s cluster on some ports, k3s cluster has full local net communication
      {
        "src": ["tag:acl-k3s", "10.42.0.0/16", "2001:cafe:42::/56"],
        "dst": ["tag:acl-k3s", "10.42.0.0/16", "2001:cafe:42::/56"],
        "ip":  ["*"],
      },
      {
        "src": ["autogroup:admin"],
        "dst": ["tag:acl-k3s", "10.42.0.0/16", "2001:cafe:42::/56"],
        "ip":  ["*"],
      },

      // tinkering devices can freely communicate and everyone can access them in the tailnet
      {
        "src": ["tag:acl-tinkering"],
        "dst": ["tag:acl-tinkering"],
        "ip":  ["*"],
      },
      {
        "src": ["autogroup:member"],
        "dst": ["tag:acl-tinkering"],
        "ip":  ["*"],
      },
    ],

    // Define users and devices that can use Tailscale SSH.
    "ssh": [
      // Anyone can access it's own devices without asking
      {
        "action": "accept",
        "src":    ["autogroup:member"],
        "dst":    ["autogroup:self"],
        "users":  ["autogroup:nonroot", "root"],
      },

      // Anyone can access tinkering devices without asking
      {
        "action": "accept",
        "src":    ["autogroup:member"],
        "dst":    ["tag:acl-tinkering"],
        "users":  ["autogroup:nonroot", "root"],
      },

      // Admins can access k3s cluster nodes without asking
      {
        "action": "accept",
        "src":    ["autogroup:admin"],
        "dst":    ["tag:acl-k3s"],
        "users":  ["autogroup:nonroot"],
      },

      // Admins can access KVM devices with asking
      {
        "action": "check",
        "src":    ["autogroup:admin"],
        "dst":    ["tag:acl-kvm"],
        "users":  ["autogroup:nonroot", "root"],
      },
    ],

    // Test access rules every time they're saved.
    "tests": [
      {
        "src":    "technat@technat.ch",
        "accept": ["tag:acl-tinkering:22"],
      },
      {
        "src":    "technat@technat.ch",
        "accept": ["tag:acl-kvm:22"],
      },
      {
        "src":    "technat@technat.ch",
        "accept": ["tag:acl-k3s:6443"],
      },
      {
        "src":    "tag:acl-k3s",
        "accept": ["tag:acl-k3s:6443"],
      },
      {
        "src":    "10.42.0.1", // some pod to CP
        "accept": ["tag:acl-k3s:6443"],
      },
      {
        "src":    "10.42.0.1", // some pod to pod
        "accept": ["10.42.0.2:80"],
      },
    ],
  }
  EOF
}
