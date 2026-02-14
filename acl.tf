resource "tailscale_acl" "as_hujson" {
  acl = <<EOF
  {
    "tagOwners": {
      "tag:feature-exitNode":  ["autogroup:admin"], // devices with this tag are grantaed exit-node advertisement automatically
      "tag:feature-funnel":    ["autogroup:admin"], // deviecs with this tag are granted funnel permissions automatically
      "tag:acl-tinkering":     ["autogroup:admin"], // tag for random tinkering devices
      "tag:acl-backup":        ["autogroup:admin"], // tag for backup NAS devices
      "tag:acl-k3s":           ["autogroup:admin"], // tag for servers in the k3s cluster
    },

    "autoApprovers": {
      "routes": {
        "192.168.0.0/16":    ["tag:acl-backup"], // one backup NAS uses this
        "10.42.0.0/16":      ["tag:acl-k3s"], // default k3s podCIDR
        "2001:cafe:42::/56": ["tag:acl-k3s"], // default k3s podCIDR
      },
      "exitNode": ["tag:feature-exitNode"], // auto-approve exit-nodes that have the tag
    },

    "nodeAttrs": [
      {
        "target": ["tag:feature-funnel"],
        "attr":   ["funnel"],
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
        "src": ["autogroup:admin"],
        "dst": ["tag:acl-backup", "192.168.1.0/24"],
        "ip":  ["445"],
      },

      {
        "src": ["tag:acl-backup"],
        "dst": ["tag:acl-backup"],
        "ip":  ["*"],
      },

      // admins can access the k3s cluster on some ports, k3s cluster has full local net communication
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

      // admins are allowed to access the local LAN
      {
        "src": ["autogroup:admin"],
        "dst": ["192.168.250.0/24"],
        "ip":  ["*"],
      },
    ],

    // Define postures that will be applied to all rules without any specific
    // srcPosture definition.
    // "defaultSrcPosture": [
    //      "posture:anyMac",
    // ],

    // Define device posture rules requiring devices to meet
    // certain criteria to access parts of your system.
    // "postures": {
    //      // Require devices running macOS, a stable Tailscale
    //      // version and auto update enabled for Tailscale.
    // 	"posture:autoUpdateMac": [
    // 	    "node:os == 'macos'",
    // 	    "node:tsReleaseTrack == 'stable'",
    // 	    "node:tsAutoUpdate",
    // 	],
    //      // Require devices running macOS and a stable
    //      // Tailscale version.
    // 	"posture:anyMac": [
    // 	    "node:os == 'macos'",
    // 	    "node:tsReleaseTrack == 'stable'",
    // 	],
    // },

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

      // Admins can access backup devices with asking
      {
        "action": "check",
        "src":    ["autogroup:admin"],
        "dst":    ["tag:acl-backup"],
        "users":  ["autogroup:nonroot"],
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
