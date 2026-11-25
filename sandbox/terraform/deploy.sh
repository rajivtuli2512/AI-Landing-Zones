#!/usr/bin/env bash
# Pulls upstream Terraform at a pinned commit and runs it with the sandbox tfvars.
set -euo pipefail
UPSTREAM=https://github.com/Azure/agent-landing-zone
COMMIT=b0fd3faf276f9944e2634d37818653301890bc7f
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$HERE/.upstream"
ACTION="${1:-plan}"   # plan | apply | destroy

if [ ! -d "$WORK/.git" ]; then
  git clone --filter=blob:none "$UPSTREAM" "$WORK"
fi
git -C "$WORK" fetch --depth 1 origin "$COMMIT"
git -C "$WORK" checkout -q "$COMMIT"

cd "$WORK/infra/terraform"
terraform init -upgrade
case "$ACTION" in
  plan)    terraform plan    -var-file="$HERE/sandbox.tfvars" -out="$HERE/sandbox.tfplan" ;;
  apply)   terraform apply   "$HERE/sandbox.tfplan" ;;
  destroy) terraform destroy -var-file="$HERE/sandbox.tfvars" ;;
  *) echo "usage: $0 [plan|apply|destroy]"; exit 1 ;;
esac
