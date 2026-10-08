# Maintainer TODO — owner-only / time-gated tasks

Tasks a contributor cannot complete (they need repository secrets or org-admin
access). Kept here so the public issue backlog stays contributor-ready.

## Owner-only

- **Set the `TESTNET_THROWAWAY_SECRET_KEY` repository secret.** The
  `CONTRACT_ID` **variable** is set
  (`CAEDHSOD3TXIAZF2BZMMNX7A2OKBCVE4WU7A6RWTHGGHWHJXHEQUMAT4`), but no secret
  exists on the repository, and the local throwaway key file
  (`.deploy/testnet-throwaway.secret`) is not present in the checkout. Without
  it, `demo-restore.yml` cannot run.
  Set it with:
  `gh secret set TESTNET_THROWAWAY_SECRET_KEY --body "$(cat .deploy/testnet-throwaway.secret)"`.
- **Capture the restore transcript** once the secret is set: trigger
  `demo-restore.yml`, then commit its output to `.transcripts/`. The Healthy and
  Archived phases are already captured (`01`–`05`).

## Org / onboarding (owner action)

- Confirm the repository is approved for the Drips Wave program.
- Confirm each GitBook space's Git Sync still points at the org repos.

## Closed as already-done / owner-only in the backlog cleanup

- *Enable branch protection with the real required checks* — done (`contract-tests`).
- *Configure Actions variables/secrets and trigger demo-scan live* — variable set,
  scheduled scan live; the secret is tracked above.
- *Validate contracts.yml against the action's schema* — done (`scripts/validate-contracts-schema.py` + tests).
- *Add a standalone-network rehearsal mode* — done (`docs/standalone-rehearsal.md`).
