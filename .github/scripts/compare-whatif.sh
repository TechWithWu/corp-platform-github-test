#!/usr/bin/env bash
# ==============================================================================
# Script: compare-whatif.sh
# Purpose: Compares PR What-If against Main What-If.
#          If no PR was associated, formats the direct What-If results.
#          Handles large outputs gracefully with artifact download instructions.
# ==============================================================================

set -euo pipefail

PR_WHATIF_FILE="/tmp/pr-whatif.txt"
MAIN_WHATIF_FILE="/tmp/main-whatif.txt"
DIFF_FILE="/tmp/whatif-diff.patch"
SUMMARY_FILE="/tmp/comparison-summary.md"
MAX_PREVIEW_LEN=40000

HAS_PR="false"
PR_NUMBER="${PR_NUMBER:-}"

if [ -f "/tmp/pr-whatif-meta.json" ]; then
  PR_HEAD_SHA=""
  if command -v jq >/dev/null 2>&1; then
    PR_HEAD_SHA=$(jq -r '.head_sha // empty' /tmp/pr-whatif-meta.json 2>/dev/null || echo "")
  else
    PR_HEAD_SHA=$(node -e "
      try {
        const m = require('/tmp/pr-whatif-meta.json');
        console.log(m.head_sha || '');
      } catch { console.log(''); }
    ")
  fi

  if [ -n "$PR_HEAD_SHA" ] && [ "$PR_HEAD_SHA" != "null" ] && [ -s "$PR_WHATIF_FILE" ]; then
    HAS_PR="true"
  fi
fi

rm -f "$DIFF_FILE" "$SUMMARY_FILE"

if [ "$HAS_PR" = "true" ]; then
  echo "Comparing PR What-If plan against Main What-If plan..."
  set +e
  diff -u "$PR_WHATIF_FILE" "$MAIN_WHATIF_FILE" > "$DIFF_FILE"
  DIFF_RC=$?
  set -e

  if [ "$DIFF_RC" -eq 0 ]; then
    HAS_CHANGES="false"
    DIFF_CONTENT="No differences detected between PR what-if plan and main what-if plan."
  else
    HAS_CHANGES="true"
    DIFF_CONTENT=$(cat "$DIFF_FILE")
  fi

  # Check size of diff
  DIFF_LEN=${#DIFF_CONTENT}
  IS_TRUNCATED="false"
  if [ "$DIFF_LEN" -gt "$MAX_PREVIEW_LEN" ]; then
    DIFF_CONTENT="${DIFF_CONTENT:0:$MAX_PREVIEW_LEN}
... [Output truncated due to character limits. Please download the attached workflow artifact for full line-by-line inspection]"
    IS_TRUNCATED="true"
  fi

  {
    echo "## 📊 What-If Comparison: PR vs. \`main\` (\`${STACK_NAME:-financeDeploymentStack}\`)"
    echo ""
    if [ -n "${PORTAL_STACK_URL:-}" ]; then
      echo "🔗 **Azure Portal Resource:** [Open Deployment Stack in Azure](${PORTAL_STACK_URL})"
      echo ""
    fi
    if [ "$HAS_CHANGES" = "true" ]; then
      echo "⚠️ **Changes detected between PR What-If and Main What-If.** Review diff below before proceeding."
    else
      echo "✅ **Clean Plan Match:** Main What-If matches the plan approved in the pull request."
    fi
    echo ""
    if [ "$IS_TRUNCATED" = "true" ]; then
      echo "> ⚠️ **Note:** The diff output is very large. Please download and open the attached workflow artifact for full inspection."
      echo ""
    fi
    echo "### Diff (PR Plan -> Main Plan)"
    echo '```diff'
    echo "$DIFF_CONTENT"
    echo '```'
    echo ""
    echo "<details><summary>Full Main What-If Raw Output</summary>"
    echo ""
    echo '```text'
    if [ -f "$MAIN_WHATIF_FILE" ]; then
      MAIN_TEXT=$(cat "$MAIN_WHATIF_FILE")
      if [ ${#MAIN_TEXT} -gt 25000 ]; then
        echo "${MAIN_TEXT:0:25000}"
        echo "... [Full output stored in uploaded workflow artifact]"
      else
        echo "$MAIN_TEXT"
      fi
    fi
    echo '```'
    echo ""
    echo "</details>"
  } > "$SUMMARY_FILE"

else
  # Direct push or manual run without a PR
  echo "No PR what-if plan found. Presenting direct What-If results..."
  HAS_CHANGES="false"

  MAIN_TEXT=""
  if [ -f "$MAIN_WHATIF_FILE" ]; then
    MAIN_TEXT=$(cat "$MAIN_WHATIF_FILE")
  fi

  MAIN_LEN=${#MAIN_TEXT}
  IS_TRUNCATED="false"
  if [ "$MAIN_LEN" -gt "$MAX_PREVIEW_LEN" ]; then
    MAIN_DISPLAY="${MAIN_TEXT:0:$MAX_PREVIEW_LEN}
... [Output truncated due to character limits. Please download the attached workflow artifact for full inspection]"
    IS_TRUNCATED="true"
  else
    MAIN_DISPLAY="$MAIN_TEXT"
  fi

  {
    echo "## 🔍 Direct What-If Results (\`${STACK_NAME:-financeDeploymentStack}\`)"
    echo ""
    if [ -n "${PORTAL_STACK_URL:-}" ]; then
      echo "🔗 **Azure Portal Resource:** [Open Deployment Stack in Azure](${PORTAL_STACK_URL})"
      echo ""
    fi
    echo "*(Run initiated via direct push or manual dispatch without an associated PR)*"
    echo ""
    if [ "$IS_TRUNCATED" = "true" ]; then
      echo "> ⚠️ **Note:** What-If output is very large. Please download and open the attached workflow artifact for complete inspection."
      echo ""
    fi
    echo "### What-If Plan"
    echo '```text'
    echo "$MAIN_DISPLAY"
    echo '```'
  } > "$SUMMARY_FILE"
fi

# Append to GITHUB_STEP_SUMMARY if available
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  cat "$SUMMARY_FILE" >> "$GITHUB_STEP_SUMMARY"
fi

# Export outputs
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "has_pr=$HAS_PR"
    echo "has_changes=$HAS_CHANGES"
  } >> "$GITHUB_OUTPUT"
fi
