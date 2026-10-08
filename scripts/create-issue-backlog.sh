#!/usr/bin/env bash
#
# create-issue-backlog.sh — idempotently file the contributor-ready backlog for
# archival-fixtures-demo.
#
# Idempotent: skips any issue whose exact title already exists (open or closed),
# and uses `gh label create --force` so labels are created/updated safely.
#
# Usage:
#   ./scripts/create-issue-backlog.sh
#   GITHUB_REPOSITORY=owner/repo ./scripts/create-issue-backlog.sh
#
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-stellar-archival-labs/archival-fixtures-demo}"
WAVE_LABEL="Stellar Wave"

gh label create "$WAVE_LABEL" --repo "$REPO" --force \
  --color "6f42c1" --description "Scoped for a Drips Wave contributor sprint" >/dev/null

EXISTING_TITLES="$(gh issue list --repo "$REPO" --state all --limit 500 --json title --jq '.[].title')"

mk() {
  local title="$1" body="$2"
  if printf '%s\n' "$EXISTING_TITLES" | grep -Fxq "$title"; then
    echo "skip (already exists): $title"
    return 0
  fi
  gh issue create --repo "$REPO" --title "$title" --label "$WAVE_LABEL" --body "$body" >/dev/null
  echo "created: $title"
}

mk "Add an Instance-storage fixture with a distinct storage profile" "$(cat <<'BODY'
## Summary
The demo currently ships one fixture: a single *persistent* contract-data entry
(`VALUE`). The original plan called for varied storage profiles so the whole
matrix of Soroban storage kinds is observable. Add a fixture that exercises a
contract **instance** entry with its own TTL behaviour.

## Why it matters
Instance and data entries archive on different schedules and are remediated
differently. A fixture that isolates the instance entry makes those differences
concrete instead of theoretical.

## Acceptance Criteria
- [ ] A deployable fixture (or a mode of the existing contract) whose notable entry is the contract instance.
- [ ] `contracts.yml` documents the fixture (kind, durability, expected bands).
- [ ] An off-chain read (`scripts/read-entry-ttl.py`) works for it.
- [ ] README lists the fixture alongside the existing persistent one.

## Tech Stack / files to touch
Rust (soroban-sdk), bash, Python. `contracts/`, `contracts.yml`, `scripts/`, `README.md`.

## Out of scope
Mainnet; all fixtures stay TESTNET-ONLY.
BODY
)"

mk "Add a Temporary-storage fixture (temporary durability)" "$(cat <<'BODY'
## Summary
Add a fixture whose notable entry uses **temporary** durability, which decays on
a different schedule than persistent storage and cannot be restored the same way.

## Why it matters
Temporary vs persistent durability is a common source of confusion; a live,
decaying temporary entry makes the difference observable end to end.

## Acceptance Criteria
- [ ] A deployable fixture with a temporary-durability entry.
- [ ] `contracts.yml` records `durability: temporary` and the expected bands.
- [ ] `scripts/read-entry-ttl.py --durability temporary` reads it correctly.
- [ ] README explains the temporary-vs-persistent distinction for this fixture.

## Tech Stack / files to touch
Rust (soroban-sdk), bash, Python. `contracts/`, `contracts.yml`, `scripts/`, `README.md`.

## Out of scope
Restoring temporary entries (protocol does not restore them the same way).
BODY
)"

mk "Add WSL and macOS setup notes" "$(cat <<'BODY'
## Summary
The scripts assume a Unix-like shell. Document the exact setup for WSL (Windows)
and macOS so contributors on those platforms can run the demo without guesswork.

## Why it matters
The upstream `stellar` CLI and the `wasm32v1-none` target differ by platform;
undocumented platform quirks block first-time contributors.

## Acceptance Criteria
- [ ] A section covering WSL: bash version, `curl`/`jq`, Windows path caveats.
- [ ] A section covering macOS: Homebrew prerequisites, `shasum` vs `sha256sum`.
- [ ] Notes that the sentinel release binaries are Linux/macOS only.
- [ ] Linked from the README prerequisites.

## Tech Stack / files to touch
Markdown. `README.md`, `docs-site/developer-guide/`, `CONTRIBUTING.md`.

## Out of scope
Native Windows (non-WSL) support.
BODY
)"

mk "Add a redeploy helper that syncs contracts.yml with the new contract id" "$(cat <<'BODY'
## Summary
`scripts/deploy-and-shrink-ttl.sh --force` deploys a fresh contract and writes
`.deploy/contract-id.txt`, but `contracts.yml`'s literal `address` must then be
updated by hand. Add a small helper (or a `--update-manifest` flag) that rewrites
the manifest's `address` to the new id.

## Why it matters
A redeploy that misses the manifest update silently points the consumer at an
archived contract — exactly the kind of drift this suite exists to make visible.

## Acceptance Criteria
- [ ] After a `--force` deploy, `contracts.yml`'s `address` matches the new id (in place, preserving comments/format).
- [ ] The helper is idempotent and no-ops when already in sync.
- [ ] `scripts/tests/` covers the rewrite against a fixture manifest.
- [ ] README documents the flow.

## Tech Stack / files to touch
Bash + Python. `scripts/deploy-and-shrink-ttl.sh`, a new helper, `scripts/tests/`, `README.md`.

## Out of scope
Auto-committing the change.
BODY
)"

mk "Add a test that the configured min persistent TTL matches the live network" "$(cat <<'BODY'
## Summary
`scripts/lib.sh` and `contracts.yml` hardcode `min_persistent_ttl_ledgers: 120960`.
Network parameters can change. Add a check that compares the configured value
against the live network's actual `minPersistentTTL` (read from the
`STATE_ARCHIVAL` config-setting entry) and warns/fails on drift.

## Why it matters
If the network raises the minimum TTL, the documented "~7 days" timeline and the
band thresholds silently become wrong.

## Acceptance Criteria
- [ ] A read-only check reads the live `minPersistentTTL`.
- [ ] It compares against the value in `contracts.yml`/`lib.sh` and reports drift.
- [ ] Safe to run in CI (read-only; no key).
- [ ] Documented; wired into `test-contract.yml` as an optional/soft check.

## Tech Stack / files to touch
Python (stdlib) + bash. `scripts/read-entry-ttl.py` (or a sibling), `contracts.yml`, `.github/workflows/test-contract.yml`.

## Out of scope
Auto-updating the configured value — surfacing drift is the goal.
BODY
)"

echo "backlog complete for $REPO"
