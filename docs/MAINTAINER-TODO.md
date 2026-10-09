# Maintainer TODO — owner-only / time-gated tasks

Tasks a contributor cannot complete (they need repository secrets or org-admin
access). Kept here so the public issue backlog stays contributor-ready.

## Owner-only

- **`TESTNET_THROWAWAY_SECRET_KEY` repository secret — no longer required.**
  The `CONTRACT_ID` **variable** is set
  (`CAEDHSOD3TXIAZF2BZMMNX7A2OKBCVE4WU7A6RWTHGGHWHJXHEQUMAT4`). `demo-restore.yml`
  now restores the contract with a throwaway testnet key that it generates and
  friendbot-funds at runtime — `RestoreFootprintOp` is permissionless and the
  demo contract's `extend` is not owner-gated, so any funded testnet account can
  do the restore. Set the secret only if you want to pin a specific key:
  `gh secret set TESTNET_THROWAWAY_SECRET_KEY --body "$(cat .deploy/testnet-throwaway.secret)"`.
- **Capture the restore transcript**: trigger `demo-restore.yml`, then merge the
  `auto/transcripts-restore` PR it produces. The Healthy and Archived phases are
  already captured (`01`–`05`).

## Org / onboarding (owner action)

- Keep **Settings → Actions → General → "Allow GitHub Actions to create and
  approve pull requests"** enabled, at the ORGANIZATION level
  (`orgs/stellar-archival-labs/actions/permissions/workflow`) and on this
  repository. `capture-transcript.yml` and `capture-restore-transcript.yml` open
  their transcript PRs with the `GITHUB_TOKEN`, and the org policy blocks that
  by default (`409: The organization does not allow GitHub Actions to create or
  approve pull requests`).
- Confirm the repository is approved for the Drips Wave program.
- Confirm each GitBook space's Git Sync still points at the org repos.

## Closed as already-done / owner-only in the backlog cleanup

- *Enable branch protection with the real required checks* — done (`contract-tests`).
- *Configure Actions variables/secrets and trigger demo-scan live* — variable set,
  scheduled scan live; the secret is tracked above.
- *Validate contracts.yml against the action's schema* — done (`scripts/validate-contracts-schema.py` + tests).
- *Add a standalone-network rehearsal mode* — done (`docs/standalone-rehearsal.md`).
