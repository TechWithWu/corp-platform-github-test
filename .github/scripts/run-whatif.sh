#!/usr/bin/env bash
# ==============================================================================
# Script: run-whatif.sh
# Purpose: Executes az stack-whatif sub create, saves the raw plan,
#          generates Azure Portal HTTPS links, and packages JSON metadata.
# ==============================================================================

set -euo pipefail

# Ensure required parameters are provided
STACK_NAME="${STACK_NAME:?STACK_NAME is required}"
LOCATION="${LOCATION:?LOCATION is required}"
TEMPLATE_FILE="${TEMPLATE_FILE:?TEMPLATE_FILE is required}"
PARAMETERS_FILE="${PARAMETERS_FILE:?PARAMETERS_FILE is required}"
AOU="${AOU:-deleteAll}"
DENY="${DENY:-denyWriteAndDelete}"
RETENTION="${RETENTION:-PT1H}"
PIPELINE_SP_OBJECT_ID="${PIPELINE_SP_OBJECT_ID:-00000000-0000-0000-0000-000000000000}"

PR_NUMBER="${PR_NUMBER:-}"
HEAD_SHA="${HEAD_SHA:-$(git rev-parse HEAD 2>/dev/null || echo 'HEAD')}"
RUN_ID="${GITHUB_RUN_ID:-0}"
RUN_ATTEMPT="${GITHUB_RUN_ATTEMPT:-1}"
SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"
REPOSITORY="${GITHUB_REPOSITORY:-local/repo}"
RUN_URL="${SERVER_URL}/${REPOSITORY}/actions/runs/${RUN_ID}"

# Azure Context
SUB_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
STACK_ID="/subscriptions/${SUB_ID}/providers/Microsoft.Resources/deploymentStacks/${STACK_NAME}"
PORTAL_STACK_URL="https://portal.azure.com/#@${TENANT_ID}/resource${STACK_ID}"

TS_UTC=$(date -u +"%Y%m%d-%H%M%S-%3N")
WHATIF_NAME="wi-${STACK_NAME}-${TS_UTC}-${RUN_ATTEMPT}"
WHATIF_RESOURCE_ID="${STACK_ID%/deploymentStacks/*}/providers/Microsoft.Resources/deploymentStacksWhatIfResults/${WHATIF_NAME}"

CMD_STR="az stack-whatif sub create --name \"${WHATIF_NAME}\" --stack-id \"${STACK_ID}\" --location \"${LOCATION}\" --template-file \"${TEMPLATE_FILE}\" --parameters \"${PARAMETERS_FILE}\" --action-on-unmanage \"${AOU}\" --deny-settings-mode \"${DENY}\" --validation-level \"ProviderNoRbac\" --deny-settings-apply-to-child-scopes --deny-settings-excluded-principals \"${PIPELINE_SP_OBJECT_ID}\" --retention-interval \"${RETENTION}\""

echo "Executing What-If command:"
echo "$ $CMD_STR"

# Execute What-If and capture to file and console
{
  echo "$ $CMD_STR"
  echo ""
  az stack-whatif sub create \
    --name "${WHATIF_NAME}" \
    --stack-id "${STACK_ID}" \
    --location "${LOCATION}" \
    --template-file "${TEMPLATE_FILE}" \
    --parameters "${PARAMETERS_FILE}" \
    --action-on-unmanage "${AOU}" \
    --deny-settings-mode "${DENY}" \
    --validation-level "ProviderNoRbac" \
    --deny-settings-apply-to-child-scopes \
    --deny-settings-excluded-principals "${PIPELINE_SP_OBJECT_ID}" \
    --retention-interval "${RETENTION}" 2>&1
} | tee /tmp/whatif-raw.txt

# Package metadata JSON (using jq or node)
if command -v jq >/dev/null 2>&1; then
  jq -n \
    --arg pr_number "$PR_NUMBER" \
    --arg head_sha "$HEAD_SHA" \
    --arg whatif_name "$WHATIF_NAME" \
    --arg whatif_resource_id "$WHATIF_RESOURCE_ID" \
    --arg stack_id "$STACK_ID" \
    --arg portal_stack_url "$PORTAL_STACK_URL" \
    --arg run_url "$RUN_URL" \
    --arg command "$CMD_STR" \
    --rawfile plan /tmp/whatif-raw.txt \
    '{
      pr_number: (if $pr_number == "" then null else ($pr_number | tonumber? // $pr_number) end),
      head_sha: $head_sha,
      whatif_name: $whatif_name,
      whatif_resource_id: $whatif_resource_id,
      stack_id: $stack_id,
      portal_stack_url: $portal_stack_url,
      run_url: $run_url,
      command: $command,
      plan: $plan
    }' > /tmp/whatif-payload.json
else
  node -e "
    const fs = require('fs');
    const plan = fs.existsSync('/tmp/whatif-raw.txt') ? fs.readFileSync('/tmp/whatif-raw.txt', 'utf8') : '';
    const prNum = '$PR_NUMBER' ? Number('$PR_NUMBER') || '$PR_NUMBER' : null;
    const payload = {
      pr_number: prNum,
      head_sha: '$HEAD_SHA',
      whatif_name: '$WHATIF_NAME',
      whatif_resource_id: '$WHATIF_RESOURCE_ID',
      stack_id: '$STACK_ID',
      portal_stack_url: '$PORTAL_STACK_URL',
      run_url: '$RUN_URL',
      command: process.argv[1],
      plan: plan
    };
    fs.writeFileSync('/tmp/whatif-payload.json', JSON.stringify(payload, null, 2));
  " "$CMD_STR"
fi

# Step outputs
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "whatif_name=$WHATIF_NAME"
    echo "whatif_resource_id=$WHATIF_RESOURCE_ID"
    echo "stack_id=$STACK_ID"
    echo "portal_stack_url=$PORTAL_STACK_URL"
    echo "command=$CMD_STR"
  } >> "$GITHUB_OUTPUT"
fi

echo "What-If execution complete. Payload saved to /tmp/whatif-payload.json."
