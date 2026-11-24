#!/usr/bin/env bash
# ==============================================================================
# Script: load-config.sh
# Purpose: Loads environment configuration from .github/config/env.<env>.json
#          and sets GitHub Actions environment variables and step outputs.
# ==============================================================================

set -euo pipefail

ENV_TARGET="${1:-prod}"
CONFIG_FILE=".github/config/env.${ENV_TARGET}.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "::error ::Configuration file $CONFIG_FILE does not exist!"
  exit 1
fi

echo "Loading configuration from $CONFIG_FILE..."

# Helper to read JSON field with jq or node fallback
get_json_val() {
  local key="$1"
  local default_val="${2:-}"
  if command -v jq >/dev/null 2>&1; then
    local val
    val=$(jq -r ".$key // empty" "$CONFIG_FILE")
    if [ -z "$val" ] || [ "$val" = "null" ]; then
      echo "$default_val"
    else
      echo "$val"
    fi
  else
    node -e "
      const cfg = require('./$CONFIG_FILE');
      const val = cfg['$key'];
      console.log(val !== undefined && val !== null && val !== '' ? val : '$default_val');
    "
  fi
}

STACK_NAME=$(get_json_val "STACK_NAME" "financeDeploymentStack")
LOCATION=$(get_json_val "LOCATION" "centralus")
TEMPLATE_FILE=$(get_json_val "TEMPLATE_FILE" "bicep/main.bicep")
PARAMETERS_FILE=$(get_json_val "PARAMETERS_FILE" "bicep/main.prod.bicepparam")
DEFAULT_SP_OBJ_ID=$(get_json_val "PIPELINE_SP_OBJECT_ID" "00000000-0000-0000-0000-000000000000")
AOU=$(get_json_val "AOU" "deleteAll")
DENY=$(get_json_val "DENY" "denyWriteAndDelete")
RETENTION=$(get_json_val "RETENTION" "PT1H")

# Allow secret or variable override if supplied via environment
PIPELINE_SP_OBJECT_ID="${PIPELINE_SP_OBJECT_ID_OVERRIDE:-$DEFAULT_SP_OBJ_ID}"
if [ -z "$PIPELINE_SP_OBJECT_ID" ] || [ "$PIPELINE_SP_OBJECT_ID" = "null" ]; then
  PIPELINE_SP_OBJECT_ID="00000000-0000-0000-0000-000000000000"
fi

echo "Loaded configuration:"
echo "  STACK_NAME=$STACK_NAME"
echo "  LOCATION=$LOCATION"
echo "  TEMPLATE_FILE=$TEMPLATE_FILE"
echo "  PARAMETERS_FILE=$PARAMETERS_FILE"
echo "  PIPELINE_SP_OBJECT_ID=$PIPELINE_SP_OBJECT_ID"
echo "  AOU=$AOU"
echo "  DENY=$DENY"
echo "  RETENTION=$RETENTION"

# Export to GITHUB_ENV if in GitHub Actions
if [ -n "${GITHUB_ENV:-}" ]; then
  {
    echo "STACK_NAME=$STACK_NAME"
    echo "LOCATION=$LOCATION"
    echo "TEMPLATE_FILE=$TEMPLATE_FILE"
    echo "PARAMETERS_FILE=$PARAMETERS_FILE"
    echo "PIPELINE_SP_OBJECT_ID=$PIPELINE_SP_OBJECT_ID"
    echo "AOU=$AOU"
    echo "DENY=$DENY"
    echo "RETENTION=$RETENTION"
  } >> "$GITHUB_ENV"
fi

# Export to GITHUB_OUTPUT if in GitHub Actions
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "stack_name=$STACK_NAME"
    echo "location=$LOCATION"
    echo "template_file=$TEMPLATE_FILE"
    echo "parameters_file=$PARAMETERS_FILE"
    echo "pipeline_sp_object_id=$PIPELINE_SP_OBJECT_ID"
    echo "aou=$AOU"
    echo "deny=$DENY"
    echo "retention=$RETENTION"
  } >> "$GITHUB_OUTPUT"
fi
