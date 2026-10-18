---
title: Lessons Learned (detail)
description: Full-detail operational lessons moved out of MEMORY.md; MEMORY.md keeps one-line summaries
tags: [lessons, ops]
timestamp: 2026-10-18T00:00:00Z
---

# Lessons (detail)
Older/settled lessons: [lessons-history.md](/topics/lessons-history.md).

## Sandbox / Bash quirks
- **Secret expansion in curl headers is blocked**; a skill then misreads auth failure as "key not set". Use `./secretcurl` with a literal `{ENV_NAME}` placeholder. The old prefetch-cache workaround is retired.
- **Runner hook rejects `$(...)`, `$VAR`, and `>` redirection** in skill bash. Only `${today}` and `${var}` are injected; `${today_minus_N}` is a phantom that silently breaks date filters. For redirection-shaped work (3-way merge) drive `git` from Python subprocess (`aeon-update` PR #198, 08-25).
- **Extended 09-21 (shiplog, interactive):** bare `$VAR` reads (`[ -n "$X" ]`, `printenv X`) and `jq` reads of `/tmp/*.json` are blocked. `./secretcurl` works; write curl output to repo-local `output/.foo.json`. `gh api graphql -f query='{...}'` is blocked (braces) - put the query in a `.graphql` file and use `-F query=@file`. [source: logs/2026-09-21#shiplog]
- **Extended 10-11 (tweet-digest):** `jq --arg name "$val"` is blocked even single-quoted; use jq's own `as $d` binding. Don't compare raw `createdAt` strings ("Thu Oct 08" vs "Sun Oct 11") - convert via `strptime`/`strftime`. [source: logs/2026-10-11#tweet-digest]
- Compound bash (`;`/`&&`) is auto-denied in the non-interactive sandbox - one operation per Bash call.
- Pushing under `.github/workflows/` needs a token with `workflows` scope.
- `changelog` push-to: fresh shallow clone can fail `git push` ("could not read Username") - run `gh auth setup-git` first (09-07).
- `changelog` B.4.1: `npx @biomejs/biome format --write <path-outside-cwd>` reads config from cwd, not the file's dir - reformatted a whole 8500-line file (09-28). Pass `--config-path <clone-dir>`; always `git diff --stat` after.

## Failure signatures
- XAI HTTP 403 = team credits exhausted (401 = bad key).
- **Zero-token/zero-cost `last_error` does NOT uniquely mean a shared LLM-gateway outage.** Confirmed 10-07 via `gh run view <id> --json jobs`: an unbounded `apt-get update` hung the bubblewrap-install step, and an `npm ETARGET` pin caused the 10-05/10-06 failures (fix PRs #255/#256). Always check the failing step before attributing to the gateway.
- Genuine gateway outages: 2026-08-31 (7 skills, subscription exhausted, fixed by pinning `gateway.provider` to `glm`, commit `b054cb0`, regressed once same-day) and 09-22 (token-report x4, secured-watch x3; self-resolved on next cron). Check `gh run list` for a later clean run before intervening.
- Actions spending-limit gate looks like a stuck dispatch (`action_required`, 0 jobs); hit 2026-08-02T19:20Z to 08-04T14:46Z (~44h) and again 08-31. Weekly-cadence skills (repo-pulse, shiplog, changelog) stay stuck past recovery - manually re-dispatch.
- `aeon-update` cron-state can stay `dispatched` after the work merged (PR #246 merged 10-05, state stale until 10-12 when a new run recovered). `changelog` showed `last_dispatch` stuck 10-08. Check `gh pr view`/`gh run list` before treating as a hang.
- 10-17: token-report failed at the "Commit results" step (git-auth bug, fixed by #269 merged 15:06 UTC); 10-18 run succeeded. [source: logs/2026-10-17#heartbeat]

## Skill-specific
- `aeon-update` + eyebrow v0.4.2+: `eyebrow verify --ci` checks per-artifact content hashes, so a SKILL.md change without a matching `eyebrowlock.json` entry = CI-red. Fix: for skills byte-identical to upstream HEAD, copy that artifact's entry from upstream's lock. A genuinely 3-way-merged SKILL.md can't get a computable hash in-sandbox - revert to base and surface as conflict. Don't hand-synthesize hashes. Headless technique that worked (PR #246): node v22 + checksum-verified eyebrow v0.5.6 via a python subprocess.
- `secured-watch`: chunk-boundary fix still leaked an RSC payload once (09-16); restrict to the `page-module__eEUUaa__chart` section and match full `aria-label`. The `note` field has been empty since before 09-22 (description moved to a sibling `<span role="tooltip">`). Skill is `enabled: false` since ~10-01; fix before re-enabling.
- `tweet-digest` skip-RTs must key on the text prefix "RT @...", not `isRetweet` (null on a real RT, 10-02).
- `repo-pulse` events-window truncation (first seen 10-05, aeon's feed exhausts the ~300-event cap); fallback fires only on non-2xx, not truncation, so busy weeks under-report. 10-12 run was complete (3 pages). Also: events API is not strictly ordered - check the min timestamp of the full set.
- apps/** npm changes in aeon have no CI build/test gate (only post-merge Vercel catches them).

## Repo hygiene
- Health issues (`health: <skill>`) don't auto-close on recovery (#230, #231 stale since 09-22).
- Scratch files pile up because `rm` isn't granted; `.tmp-sw/` got swept into commit `84b41db` (09-20). secured-watch ignored an embedded prompt-injection in a tool result (correct behavior).
