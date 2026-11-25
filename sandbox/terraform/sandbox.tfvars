# ---------------------------------------------------------------------------
# AI Landing Zone (Agent Landing Zone, Terraform) - SANDBOX / PoC profile
# Upstream: https://github.com/Azure/agent-landing-zone/tree/main/infra/terraform
# Pinned commit: b0fd3faf276f9944e2634d37818653301890bc7f (2026-11-24)
# ---------------------------------------------------------------------------

# ---- Required ----
subscriptionId    = "00000000-0000-0000-0000-000000000000" # sandbox subscription
resourceGroupName = "rg-ailz-sandbox-poc"
environmentName   = "ailzsbx"
principalId       = "00000000-0000-0000-0000-000000000000" # your Entra object ID
location          = "australiaeast" # check model + quota availability
createResourceGroup = true

# ---- Security: KEEP ON ----
networkIsolation          = true  # private endpoints, no public access
deploymentMode            = "standalone"
aiFoundryDisableLocalAuth = true  # Entra ID only, no API keys
storageAccountAllowSharedKeyAccess = false
enablePrivateLogAnalytics = true
deployKeyVault            = true
deployLogAnalytics        = true
deployAppInsights         = true
deployStorageAccount      = true
deployNsgs                = true
publicIngress             = { enabled = false }

# Egress: upstream REQUIRES a firewall (or hub next-hop) when networkIsolation = true.
# Keep it, but on the cheapest SKU.
deployAzureFirewall = true
azureFirewallSku    = "Basic"

# Access to private Foundry portal: Bastion + small jumpbox
deployVM         = true
deployJumpbox    = true
deployBastion    = true
deployNatGateway = true
bastionSkuName   = "Basic"
vmSize           = "Standard_B2as_v2"

# ---- Core AI ----
deployAiFoundry        = true
deployAfProject        = true
deployModelDeployments = true # keep model list small, low TPM (see README)
deploySearchService    = false # turn on if PoC needs RAG

# ---- Heavy / not needed for PoC: OFF ----
deployContainerApps      = false
deployContainerEnv       = false
deployContainerRegistry  = false
deployAcrTaskAgentPool   = false
deployAppConfig          = false
deployCosmosDb           = false
deployPostgreSql         = false
deploySpeechService      = false
deployGroundingWithBing  = false # sends data to public web
deployDurableTaskScheduler = false
deployHostedAgent        = false
deploySoftware           = false # skip jumpbox software bootstrap

# Skip subnets for services that are off
deployAppGatewaySubnet        = false
deployAcaEnvironmentSubnet    = false
deployDevopsBuildAgentsSubnet = false
deployPowerPlatformSubnet     = false
deployAiGatewaySubnet         = false
deployGatewaySubnet           = false

# ---- Tags ----
deploymentTags = {
  environment        = "sandbox"
  purpose            = "ai-poc"
  owner              = "REPLACE_OWNER_EMAIL"
  costCentre         = "REPLACE"
  expiryDate         = "YYYY-MM-DD"
  dataClassification = "synthetic-or-masked-only"
}
