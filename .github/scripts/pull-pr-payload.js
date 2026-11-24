/**
 * @file pull-pr-payload.js
 * @description Retrieves the PR What-If result payload associated with the commit.
 */

const fs = require('fs');

module.exports = async ({ github, context, core }) => {
  const { data: prs } = await github.rest.repos.listPullRequestsAssociatedWithCommit({
    owner: context.repo.owner,
    repo: context.repo.repo,
    commit_sha: context.sha,
  });

  let prPayload = null;
  let prNumber = '';

  if (prs && prs.length > 0) {
    prNumber = String(prs[0].number);
    console.log(`Found associated PR #${prNumber} for commit ${context.sha}`);

    const { data: comments } = await github.rest.issues.listComments({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: prs[0].number,
    });

    for (const c of [...comments].reverse()) {
      if (!c.body) continue;
      const match = c.body.match(/<!-- WHATIF_B64_START -->([\s\S]*?)<!-- WHATIF_B64_END -->/);
      if (match && match[1]) {
        try {
          prPayload = JSON.parse(Buffer.from(match[1].trim(), 'base64').toString('utf8'));
          console.log(`Extracted PR What-If payload for '${prPayload.whatif_name}'`);
          break;
        } catch (e) {
          console.warn('Failed to parse base64 payload:', e.message);
        }
      }
    }
  } else {
    console.log(`No pull request associated with commit ${context.sha}`);
  }

  if (!prPayload) {
    prPayload = {
      pr_number: prNumber || null,
      head_sha: context.sha,
      whatif_name: '(none)',
      run_url: '',
      command: '(No prior PR what-if comment found)',
      plan: ''
    };
  }

  fs.writeFileSync('/tmp/pr-whatif-meta.json', JSON.stringify(prPayload, null, 2));
  fs.writeFileSync('/tmp/pr-whatif.txt', prPayload.plan || '');

  core.setOutput('pr_number', prNumber);
  core.setOutput('has_pr_payload', prPayload.plan ? 'true' : 'false');
};
