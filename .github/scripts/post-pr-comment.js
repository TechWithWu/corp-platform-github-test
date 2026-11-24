/**
 * @file post-pr-comment.js
 * @description Reusable GitHub Script to create or update PR comments with What-If results,
 * Azure Portal HTTPS links, large-output handling, and embedded metadata.
 */

const fs = require('fs');

module.exports = async ({ github, context, mode = 'pr-whatif' }) => {
  const marker = '<!-- bicep-stack-whatif-comment -->';
  const maxCommentLen = 50000;

  // Resolve issue/PR number
  let issueNumber = context.issue?.number;
  if (!issueNumber && context.payload?.pull_request?.number) {
    issueNumber = context.payload.pull_request.number;
  }

  if (mode === 'pr-whatif') {
    if (!fs.existsSync('/tmp/whatif-payload.json')) {
      console.log('No whatif-payload.json found, skipping PR comment.');
      return;
    }

    const payload = JSON.parse(fs.readFileSync('/tmp/whatif-payload.json', 'utf8'));
    if (!issueNumber && payload.pr_number) {
      issueNumber = payload.pr_number;
    }

    if (!issueNumber) {
      console.log('No pull request number identified, skipping comment creation.');
      return;
    }

    let planText = payload.plan || '';
    let truncated = false;
    if (planText.length > maxCommentLen) {
      planText = planText.slice(0, maxCommentLen) + '\n... [Output truncated; see full log in workflow run artifacts]';
      truncated = true;
    }

    const embeddedJson = Buffer.from(JSON.stringify(payload)).toString('base64');

    const lines = [
      marker,
      `## 🔍 Deployment Stack What-If: \`${payload.whatif_name}\``,
      '',
      `- 🔗 **Azure Portal Resource Link:** [${payload.portal_stack_url || 'Open Resource in Azure Portal'}](${payload.portal_stack_url})`,
      `- 📋 **Workflow Run:** [Run #${context.runId}](${payload.run_url})`,
      `- 📦 **Commit SHA:** \`${payload.head_sha}\``,
      '',
      '### Executed Command',
      '```bash',
      payload.command,
      '```',
      '',
      '### What-If Plan Preview',
      truncated ? '> ⚠️ **Notice:** Output exceeded GitHub comment limits. Please download the attached run artifact for full inspection.' : '',
      '```text',
      planText,
      '```',
      '',
      '<details><summary>Embedded What-If Metadata (for main deployment comparison)</summary>',
      '',
      `<!-- WHATIF_B64_START -->${embeddedJson}<!-- WHATIF_B64_END -->`,
      '',
      '</details>'
    ];

    const body = lines.filter(Boolean).join('\n');

    const { data: comments } = await github.rest.issues.listComments({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: issueNumber,
    });

    const existing = comments.find(c => c.body && c.body.includes(marker));
    if (existing) {
      console.log(`Updating existing comment ${existing.id} on PR #${issueNumber}`);
      await github.rest.issues.updateComment({
        owner: context.repo.owner,
        repo: context.repo.repo,
        comment_id: existing.id,
        body,
      });
    } else {
      console.log(`Creating new comment on PR #${issueNumber}`);
      await github.rest.issues.createComment({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: issueNumber,
        body,
      });
    }
  } else if (mode === 'main-diff') {
    // Post diff comparison to PR if associated PR was found
    if (!issueNumber) {
      console.log('No PR associated with this main run; skipping PR comment.');
      return;
    }

    if (!fs.existsSync('/tmp/comparison-summary.md')) {
      console.log('No comparison-summary.md found.');
      return;
    }

    const diffMarker = '<!-- bicep-stack-main-diff-comment -->';
    const comparisonText = fs.readFileSync('/tmp/comparison-summary.md', 'utf8');

    const body = [
      diffMarker,
      comparisonText
    ].join('\n\n');

    const { data: comments } = await github.rest.issues.listComments({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: issueNumber,
    });

    const existing = comments.find(c => c.body && c.body.includes(diffMarker));
    if (existing) {
      console.log(`Updating existing diff comment ${existing.id} on PR #${issueNumber}`);
      await github.rest.issues.updateComment({
        owner: context.repo.owner,
        repo: context.repo.repo,
        comment_id: existing.id,
        body,
      });
    } else {
      console.log(`Creating new diff comment on PR #${issueNumber}`);
      await github.rest.issues.createComment({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: issueNumber,
        body,
      });
    }
  }
};
