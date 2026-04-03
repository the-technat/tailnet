resource "tailscale_acl" "as_hujson" {
  acl = <<EOF
  {
    "tagOwners": {
      "tag:feature-exitNode":  ["autogroup:admin"], // devices with this tag are granted exit-node advertisement automatically
      "tag:feature-funnel":    ["autogroup:admin"], // deviecs with this tag are granted funnel permissions automatically
      "tag:acl-backup":        ["autogroup:admin"], // tag for backup NAS devices
      "tag:acl-faultier":      ["autogroup:admin"], // tag for faultier services
      "tag:k8s-operator":      ["autogroup:admin"], // tag for the K8s operator and API endpoint
      "tag:k8s":               ["tag:k8s-operator"], //tag for services exposed via TS operator
      "tag:idp":               ["autogroup:admin"], // tag for nodes running the TSIDP server
      "tag:acl-kvm":           ["autogroup:admin"], // tag for KVM over IP devices
      "tag:acl-tinkering":     ["autogroup:admin"], // tag for random tinkering devices
    },

    "autoApprovers": {
      "routes": {
        "192.168.0.0/16":    ["tag:acl-backup"], // one backup NAS uses this
        "192.168.250.0/24":  ["tag:acl-kvm"],    // one KVM device uses this
      },
      "exitNode": ["tag:feature-exitNode"], // auto-approve exit-nodes that have the tag
      "services": { // auto-approve exposed services
        "tag:k8s": ["tag:k8s"], // for things the k8s-operator handles
      },
    },
    "groups": {
      "group:mullvad": [
        "technat@technat.ch",
      ],
      "group:funnel": [
        "technat@technat.ch",
      ],
    },
    "nodeAttrs": [
      {
        "target": ["tag:feature-funnel"],
        "attr":   ["funnel"], // grant funnel to devices with this tag
      },
      {
      "target": ["group:funnel"], // users in this group can use funnel without approval
        "attr":   ["funnel"],
      },
      {
        "target": ["group:mullvad"], // users in this group are allowed to use mullvad licenses
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

      // Faultier and faultier services are only allowed from admins
      {
        "dst": ["tag:acl-faultier"],
        "src": ["autogroup:admin"],
        "ip":  ["443"],
      },

      // Admins can access the TSIDP admin UI
      {
        // see https://github.com/tailscale/tsidp#setting-an-application-capability-grant
        "src": ["autogroup:admin"],
        "dst": ["tag:idp"], 
        "ip":  ["443"],
        "app": {
          "tailscale.com/cap/tsidp": [
            {
              // allow access to UI
              "allow_admin_ui": true,
              "allow_dcr": true,
            },
          ],
        },
      },
      // Any member and shared user can access all apps that allow "Login with TSIDP" (e.g flat auth, do authz in app)
      {
        "src": ["autogroup:member", "autogroup:shared"],
        "dst": ["tag:idp"],
        "ip":  ["443"],
        "app": {
          "tailscale.com/cap/tsidp": [
            {
              "allow_dcr": true,
              "users":     ["*"],
              "resources": ["*"],
            },
          ],
        },
      },
      // All tagged devices (i.e not users) can verify auth requests by contacting the IDP
      {
        "src": ["autogroup:tagged"],
        "dst": ["tag:idp"],
        "ip":  ["443"],
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

      // Anyone can access the Kubernetes API or exposed services of clusters (AUTH part)
      {
        "src": ["autogroup:member"],
        "dst": ["tag:k8s"],
        "ip":  ["tcp:80", "tcp:443"],
      },
      { // authorize Tailnet admins to be kubernetes admins (AUTHZ part)
        "src": ["autogroup:admin"],
        "dst": ["tag:k8s"],
        "app": {
          "tailscale.com/cap/kubernetes": [{
            "impersonate": {
              "groups": ["system:masters"],
            },
          }],
        },
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

      // Admins can access KVM devices with asking
      {
        "action": "check",
        "src":    ["autogroup:admin"],
        "dst":    ["tag:acl-kvm"],
        "users":  ["autogroup:nonroot", "root"],
      },

      // Admins can access faultier with asking
      {
        "action": "check",
        "src":    ["autogroup:admin"],
        "dst":    ["tag:acl-faultier"],
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
        "accept": ["tag:acl-faultier:443"],
      },
      {
        "src":    "tag:acl-tinkering", // some tinkering server to the backup net
        "deny": ["tag:acl-backup:5000"],
      },
      {
        "src":    "tag:acl-tinkering", // some tinkering server to the kvm devices
        "deny": ["tag:acl-kvm:443"],
      },
      {
        "src":    "tag:acl-tinkering", // some tinkering server to the idp
        "accept": ["tag:idp:443"],
      },

    ],
  }
  EOF
}
