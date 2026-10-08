<p align="center">
  <img src="assets/banner.png" alt="archival-fixtures-demo project banner" />
</p>

# archival-fixtures-demo

A deliberately short-lived Soroban contract (plus the scripts around it) that
makes **Soroban state archival** observable end-to-end on Stellar **testnet**:
deploy a contract holding one persistent entry, watch its TTL decay over
~7 days, see the entry get archived, and restore it.

[![CI](https://github.com/stellar-archival-labs/archival-fixtures-demo/actions/workflows/test-contract.yml/badge.svg)](https://github.com/stellar-archival-labs/archival-fixtures-demo/actions/workflows/test-contract.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<p align="center">
  <a href="https://stellar.expert/explorer/testnet/contract/CAEDHSOD3TXIAZF2BZMMNX7A2OKBCVE4WU7A6RWTHGGHWHJXHEQUMAT4">Live testnet contract</a> ·
  <a href="docs-site/SUMMARY.md">Documentation</a> ·
  <a href="https://soroban-state-sentinel.gitbook.io/archival-fixtures-demo/">Hosted docs</a> ·
  <a href="https://discord.gg/pMwVZf8TX">Discord</a> ·
  <a href="https://t.me/+RZKO3ffLffY0NDg0">Telegram</a>
</p>

> ⚠️ **TESTNET ONLY.** Everything in this repo signs, funds, and deploys with
> TESTNET-ONLY throwaway keys and talks to the testnet RPC. Never set a
> mainnet key or point `SOROBAN_RPC_URL` at mainnet. `scripts/lib.sh` enforces
> this posture loudly and refuses to run otherwise.

## Status at a glance

| Surface | Current status (checked 2026-10-08) |
|---|---|
| Live testnet entry | `CAEDHSOD3TXIAZF2BZMMNX7A2OKBCVE4WU7A6RWTHGGHWHJXHEQUMAT4` (key `VALUE`, persistent) |
| Health band | **Archived** — TTL `0` (latest ledger `5,084,678`); real read-only capture in `.transcripts/05-archived-read-entry-ttl.txt` |
| Timeline | Deployed 2026-09-09 (ledger 4,583,709); decayed through Critical to Archived on the real ~7-day testnet schedule |
| CI | `test-contract.yml` green on push; `demo-scan.yml` (every 6 h) now reports `band=Archived` and fails red, as designed |
| Contract unit tests | 5/5 passing |

## The idea in one paragraph

Soroban ledger entries don't live forever: each one has a time-to-live (TTL)
measured in ledgers, and the network archives persistent entries once their
TTL hits zero. The protocol enforces a **minimum** TTL when an entry is
created or restored, `extend_ttl` can only ever *raise* a TTL, and ordinary
writes **do not** extend it — so a contract whose users keep transacting can
still silently lose its persistent data when nothing watches the TTL. This
repo builds the smallest possible contract that will inevitably archive —
exactly one persistent entry, created at the network-minimum TTL and never
extended — and pairs it with the tooling to watch the decay, get alerted, and
remediate. It exists to give
[`soroban-state-sentinel`](https://github.com/stellar-archival-labs/soroban-state-sentinel)
and `action-state-watch` a real, decaying, archivable testnet entry to watch.

## Repo layout

```
contracts/rapid-expiry-demo/   the contract: one persistent entry "VALUE",
                               functions initialize / read / touch / extend,
                               plus unit tests configured with the real testnet
                               network parameters (no ttl() — contracts cannot
                               read their own TTL; it is read off-chain)
scripts/lib.sh                 shared env vars, preflight checks, RPC +
                               sentinel helpers (the TESTNET-ONLY guardrail)
scripts/deploy-and-shrink-ttl.sh   deploy (or reuse) + initialize + starting scan
scripts/trigger-eviction-wait.sh   read-only TTL watcher (polls the sentinel)
scripts/run-full-pipeline.sh       deploy -> decay -> remediate -> verify
scripts/read-entry-ttl.py          off-chain TTL read via getLedgerEntries
                                   (stdlib python; used by CI, no CLI needed)
scripts/validate-contracts-schema.py   checks contracts.yml against
                                   action-state-watch's consumer schema
scripts/tests/                     fixture tests for the validator
.github/workflows/capture-transcript.yml  auto-commits band-transition scans
.github/workflows/capture-restore-transcript.yml  auto-commits the restore log
.github/workflows/demo-scan.yml    scheduled TTL scan (self-contained,
                                   off-chain read, fails red on decay)
.github/workflows/demo-restore.yml manually-triggered restore (RestoreFootprintOp
                                   via the TESTNET-ONLY throwaway key)
.github/workflows/test-contract.yml cargo test + contracts.yml schema check
contracts.yml                  fixture manifest, written in the shape
                               action-state-watch's consumer loads. NOTE: that
                               action reads its own contracts.example.yml, not
                               this file — this is the fixture-side source of
                               truth it was seeded from (see issue #4).
docs/                          the deep dives (archival mechanics, TTL boundaries)
docs-site/                     GitBook-style documentation site (SUMMARY.md)
.transcripts/                  real terminal output from the live testnet run
CONTRIBUTING.md               contributing guide (git workflow rules)
SECURITY.md                   key-handling and disclosure policy
```

## Demo Video

The full Soroban state-archival lifecycle demonstrated by this repo has been recorded.
Watch the video here: [https://www.loom.com/share/acdeda3bfd484173b75cf8ddc2406bcf](https://www.loom.com/share/acdeda3bfd484173b75cf8ddc2406bcf)

## Documentation

The GitBook-style site lives in [`docs-site/`](docs-site/SUMMARY.md), is
published at
[https://soroban-state-sentinel.gitbook.io/archival-fixtures-demo/](https://soroban-state-sentinel.gitbook.io/archival-fixtures-demo/),
and walks through the demo end to end: the archival lifecycle, the economics
of rent, deploying, watching decay, restoring, the contract reference, and the
CI workflows. The longer reference reads are in [`docs/`](docs/):

- [`docs/surviving-soroban-state-archival.md`](docs/surviving-soroban-state-archival.md) —
  how Soroban storage expiry works, the sentinel's health bands, and how to
  survive it in production
- [`docs/setting-extend-ttl-boundaries.md`](docs/setting-extend-ttl-boundaries.md) —
  how to choose `extend_to` / `threshold` boundaries and what extensions cost

## Prerequisites

- `bash` >= 4, `curl`, `jq`
- [`stellar` CLI](https://developers.stellar.org/docs/tools/cli/stellar-cli)
- `soroban-state-sentinel` on PATH — only needed by the sentinel-driven
  scripts (`SENTINEL_BIN` overrides the binary name). Install the prebuilt
  release binary for your platform, or build from source:

  ```bash
  # prebuilt (Linux x86_64 shown; see the releases page for macOS targets)
  VERSION=v0.1.0; TARGET=x86_64-unknown-linux-gnu
  BASE="https://github.com/stellar-archival-labs/soroban-state-sentinel/releases/download/${VERSION}"
  ASSET="soroban-state-sentinel-${VERSION}-${TARGET}.tar.gz"
  curl -fsSLO "${BASE}/${ASSET}" && curl -fsSLO "${BASE}/${ASSET}.sha256"
  sha256sum --check "${ASSET}.sha256" && tar -xzf "${ASSET}"

  # or from the tagged source
  cargo install --git https://github.com/stellar-archival-labs/soroban-state-sentinel --tag v0.1.0 sentinel-cli --locked
  ```
- Rust toolchain with the `wasm32v1-none` target (Rust 1.84+; soroban-sdk 27
  no longer supports the legacy `wasm32-unknown-unknown` target) only if you
  need to build the contract WASM or run its tests

## Quick start

```bash
# 1. (optional) build + test the contract
rustup target add wasm32v1-none
cargo test --manifest-path contracts/rapid-expiry-demo/Cargo.toml

# 2. deploy (generates + friendbot-funds a TESTNET-ONLY throwaway key if
#    TESTNET_THROWAWAY_SECRET_KEY is unset; reuses existing deployment)
./scripts/deploy-and-shrink-ttl.sh

# 3. one-shot TTL / health-band check
./scripts/trigger-eviction-wait.sh --check

# 4. watch it decay (this is real time: ~6 days to Critical, ~7 to Archived)
./scripts/trigger-eviction-wait.sh --until critical

# 5. full lifecycle in one command: deploy -> decay -> remediate -> verify
./scripts/run-full-pipeline.sh --wait-for critical
```

The generated throwaway key is saved (mode 600) to `.deploy/testnet-throwaway.secret`
and reused on later runs; it holds only testnet lumens and can be discarded at
any time.

## Environment variables

All are optional (defaults shown); the only one that is truly required for
anything that signs or submits is `TESTNET_THROWAWAY_SECRET_KEY`.

| Variable | Default | Meaning |
|---|---|---|
| `SOROBAN_RPC_URL` | `https://soroban-testnet.stellar.org` | testnet RPC endpoint (testnet/localhost/standalone only) |
| `SOROBAN_NETWORK_PASSPHRASE` | `Test SDF Network ; September 2015` | must stay testnet — enforced |
| `STELLAR_CLI_BIN` | `stellar` | stellar-cli binary name/path |
| `SENTINEL_BIN` | `soroban-state-sentinel` | sentinel binary name/path |
| `TESTNET_THROWAWAY_SECRET_KEY` | *(none)* | TESTNET-ONLY throwaway `S...` key; if unset, generated + friendbot-funded |
| `RAPID_EXPIRY_WASM` | `contracts/rapid-expiry-demo/target/wasm32v1-none/release/rapid_expiry_demo.wasm` | wasm to deploy |
| `CONTRACT_ID_FILE` | `.deploy/contract-id.txt` | where the deployed contract id is persisted |
| `LEDGER_SECONDS` | `5` | testnet ledger cadence, used only for ETA math |

## The demo timeline

With current testnet network parameters (protocol 28, verified 2026-09-09 via
`getLedgerEntries` on the `STATE_ARCHIVAL` config setting) the minimum
persistent TTL is **120,960 ledgers ≈ 7 days** at the ~5 s ledger cadence:

| stage | when | entry TTL |
|---|---|---|
| deploy + `initialize()` | ledger L | 120,959 ledgers (~7 days) |
| users keep transacting, nobody extends | each ledger | −1 ledger (~5 s each) |
| sentinel flags Critical | ≈ L + 103,680 | ≤ 1 day (17,280 ledgers) |
| archived | ≈ L + 120,960 | 0 — reads/writes fail until restored |

These numbers are set by network validators and can change — verify before
trusting them (the contract and `docs/surviving-soroban-state-archival.md`
show how to read them from the ledger).

## CI: the scheduled scan and the manual restore

`.github/workflows/demo-scan.yml` runs every 6 hours (and on demand via
workflow dispatch), reads the entry TTL **off-chain** via
`getLedgerEntries` (`scripts/read-entry-ttl.py`, stdlib python — contracts
cannot read their own TTL, by protocol design), prints the health band, and
fails the run when the entry goes Critical or Archived so the decay turns
the schedule red. Setup:

1. Deploy once locally: `./scripts/deploy-and-shrink-ttl.sh`
2. Add a repository **variable** `CONTRACT_ID` = the printed contract id
3. Add a repository **secret** `TESTNET_THROWAWAY_SECRET_KEY` = the `S...`
   value in `.deploy/testnet-throwaway.secret`
4. Trigger once with the "Run workflow" button, then let the cron take over

`.github/workflows/demo-restore.yml` is the manual remediation half: run it
from the Actions UI once the scan goes red. It detects whether the entry is
archived, submits a `RestoreFootprintOp` (`stellar contract restore`) with
the same TESTNET-ONLY throwaway key, extends the TTL back to a healthy value,
and prints the post-restore TTL. No sentinel binary is needed in CI — both
workflows are self-contained with the public stellar CLI.

## Real run transcript

`.transcripts/` captures actual output from the live testnet run (real
numbers, not placeholders):

- `01-deploy-healthy.txt` — deploy + initialize + starting sentinel scan
- `02-scan-healthy.json` — sentinel `scan --json` of the live entry
- `03-wait-check.txt` — the TTL watcher's one-shot check
- `04-read-entry-ttl.txt` — the off-chain TTL read used by CI (Healthy)
- `05-archived-read-entry-ttl.txt` — the same off-chain read after archival (TTL `0`)

As of **2026-10-08** the demo entry is **Archived**: TTL `0` (latest ledger
`5,084,678`). The scheduled `demo-scan.yml` run of 2026-10-08T03:38Z agrees
(`band=Archived`, run
[#37723689615](https://github.com/stellar-archival-labs/archival-fixtures-demo/actions/runs/37723689615)).
The entry was deployed 2026-09-09 (ledger 4,583,709) and decayed on the real
~7-day testnet schedule. The **Healthy** and **Archived** bands are captured;
the **restore** transcript is not yet captured — the restore flow needs the
TESTNET-ONLY throwaway key (`.deploy/testnet-throwaway.secret`), which is not
present in this checkout.

## Faster rehearsal on a standalone network

Waiting ~7 days on testnet is the honest demo, but for iterating on the
scripts themselves, point `SOROBAN_RPC_URL` at a local standalone network
(e.g. `stellar network start` / `stellar container start`) where you control
ledger time and the whole timeline can be compressed. The scripts are
network-agnostic; only the TTL constants differ (set the standalone
`minPersistentTTL` to a small value if you want a fast rehearsal).

## How this differs from other Soroban tooling

Other developer tooling in this space targets different phases of the
contract lifecycle: **SoroScope** profiles gas/CPU cost during development
and testing, and **Soroban-Guard** does static security analysis of contract
code before deployment. This suite's distinct focus is the phase after
deployment: continuous, RPC-based monitoring of TTL / state-archival risk on
live entries, and the automated remediation (`ExtendFootprintTTLOp` /
`RestoreFootprintOp`) that keeps persistent data alive once it is in
production. If you need pre-merge footprint checks, those tools are
complementary to (not a substitute for) watching what happens to a deployed
contract's state over time.

## Maintainers

<table align="center">
<tr>
<td align="center">
<strong>Aycode01</strong> — maintainer
<br />
<a href="https://github.com/Aycode01">github.com/Aycode01</a>
</td>
</tr>
</table>

## Community

- [Discord](https://discord.gg/pMwVZf8TX)
- [Telegram](https://t.me/+RZKO3ffLffY0NDg0)

## Contributors

This repository currently has a single maintainer and no outside contributors yet.

## License

[MIT](LICENSE)