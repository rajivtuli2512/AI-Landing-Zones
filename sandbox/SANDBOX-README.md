# AI Landing Zone — Sandbox / PoC Profile (for review)

> **DRAFT for review.** Not deployed or tested in Azure yet. Run `plan` / `what-if` before anything else.

## Purpose
This profile is a light, low-cost and secure version of the AI Landing Zone for **short-lived AI PoCs**. Production security basics stay on: private endpoints, Entra-only auth, Key Vault and logging. Production-scale hosting and ingress services are switched off.

No upstream code was changed. Everything lives in `sandbox/`, so you can still pull upstream updates.

## Layout
| Path | What |
|---|---|
| `terraform/sandbox.tfvars` | **Main deliverable.** Sandbox variables for the upstream Terraform |
| `terraform/deploy.sh` | Pulls upstream Terraform at a **pinned commit** and runs plan/apply/destroy with the tfvars |
| `sandbox.parameters.json` | Same profile for the portal/ARM template (`portal/template.json`) |
| `policy-deny-cross-sub-peering.json` | Policy: no VNet peering outside the sandbox subscription |
| `policy-require-expiry-tag.json` | Policy: every resource group needs an `expiryDate` tag |

> Note: the Terraform code isn't in this repo. It lives in [Azure/agent-landing-zone](https://github.com/Azure/agent-landing-zone/tree/main/infra/terraform). `deploy.sh` pins it to commit `b0fd3fa` (2026-11-24) so results stay the same each run.

## Terraform: deploy
Prereqs: Terraform, Azure CLI (`az login`), and Owner on the sandbox subscription.
```bash
cd sandbox/terraform
# 1. Edit sandbox.tfvars: subscriptionId, principalId, location, tags
./deploy.sh plan      # review the plan + cost
./deploy.sh apply
./deploy.sh destroy   # when the PoC ends
```
State is local by default. For a shared team sandbox, add an `azurerm` backend (a storage account in a separate RG).

## Component decisions (Terraform)
| Component | Sandbox | Why |
|---|---|---|
| Foundry + project + model deployments | ✅ On | Core of the PoC. Keep TPM low. |
| `networkIsolation` (private endpoints, VNet, NSGs) | ✅ On | Secure by default |
| Entra-only auth (`aiFoundryDisableLocalAuth`, no storage shared keys) | ✅ On | No API keys to leak |
| Key Vault, Storage, Log Analytics (private), App Insights | ✅ On | Secrets, data, audit |
| Azure Firewall | ✅ On, **Basic SKU** | **Upstream requires it** when `networkIsolation = true` (or a hub next-hop). Basic is the cheapest option. |
| Bastion (**Basic**) + jumpbox (`B2as_v2`) + NAT | ✅ On, small | The only way into the private Foundry portal |
| AI Search | ❌ Off | Turn on for RAG PoCs |
| Container Apps / Env / ACR / ACR task pool | ❌ Off | Turn on if hosting an agent app |
| App Config, Cosmos, PostgreSQL, Speech, Durable Task | ❌ Off | Not needed by default |
| Grounding with Bing | ❌ Off | Sends data to the public web |
| Jumpbox software bootstrap | ❌ Off | Faster deploy |
| Unused subnets (App GW, ACA, DevOps, Power Platform, AI GW, Gateway) | ❌ Off | Smaller footprint |

**Cheaper option for a throwaway PoC:** set `networkIsolation = false` and turn off firewall, Bastion and jumpbox. It deploys much faster but uses **public endpoints**, so only do this with synthetic data and `allowedIpRanges` set.

## Guardrails at the Sandbox management group
```bash
MG=<sandbox-mg-id>
az policy definition create -n sbx-deny-xsub-peering --management-group $MG --mode All \
  --rules "$(jq .properties.policyRule ../policy-deny-cross-sub-peering.json)"
az policy definition create -n sbx-require-expiry-tag --management-group $MG --mode All \
  --rules "$(jq .properties.policyRule ../policy-require-expiry-tag.json)"
# then assign both at the MG scope
```
Also assign these built-ins: *Allowed locations*, *Allowed resource types*, *Cognitive Services accounts should disable public network access*, *…should have local authentication disabled*. Add a **budget alert** (50/80/100%).

## AI guardrails (after deploy)
- Low TPM quota per model, pay-as-you-go only (no provisioned throughput)
- Default content filters on
- **Synthetic or masked data only**, with no connections to production data
- Restrict the allowed models list
- Delete the RG once the date in `expiryDate` passes (runbook or Logic App)

## Portal/ARM alternative
```bash
az deployment group what-if -g <rg> --template-file portal/template.json \
  --parameters @sandbox/sandbox.parameters.json --parameters vmPassword=<secret>
```
The ARM version turns the firewall **off** completely (NAT Gateway handles egress), so it costs less than the Terraform version.

## Open items for reviewer
- [ ] `terraform plan` runs cleanly (not run yet, because Terraform/Azure access isn't available where this was written)
- [ ] `storageAccountAllowSharedKeyAccess = false` doesn't break upstream deployment scripts. Set it back to `true` if the plan or apply fails.
- [ ] Region, model quota, budget and expiry period confirmed
- [ ] Bastion + jumpbox, or VPN/P2S for access?
- [ ] Optional components needed (AI Search, ACA, Cosmos)?
