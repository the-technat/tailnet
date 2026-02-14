# tailnet

An attempt to configure my Tailscale account as code

## Intro

I love Infrastructure as Code. And as someone who is born with IaC, I can't live without it, not even for homelab purposes.

This repo shows how my Tailnet is configured, from the steps done manually to the things automated.

## Tier 0 Setup

At the beginning I created a tailnet account by logging into Tailscale with my preferred identity provider.

Once my tailnet was created, I was able to generate some credentials that are used by Terraform. Terraform needs an Oauth Client that can be found in the settings under "Trust Credentials". 

### Workspace

This Github repo is used by a workspace in [Terraform Cloud](https://app.terraform.io) to configure my tailnet. The following workspace variables have been added there manually:

- `ts_oauth_client_id`: sensitive var
- `ts_oauth_client_secret`: sensitive, var
- `ts_tailnet`: var
