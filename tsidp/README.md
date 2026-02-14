# Tailscale Identity Provider

[tsidp](https://github.com/tailscale/tsidp?tab=readme-ov-file) hosted on fly.io.

## Initial Setup

- Use `fly launch --no-deploy` to create the app initially (from your laptop)
- Generate token for Github workflow and set as action secret named `FLY_ORG_API_TOKEN`
 - use `fly tokens create deploy -x 999999h` to do this locally
- Push to the repo and let the workflow do the rest
- To initially join the idp to the tailnet, check the logs of the app for the login URL
- Once added to the tailnet, ensure the IDP is tagged using `tag:idp` 

## Tailscale config 

See [../acl.tf](../acl.tf) for the app configs
