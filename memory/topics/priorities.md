---
title: Next Priorities (detail)
description: Full-detail open priorities moved out of MEMORY.md; MEMORY.md keeps one-line summaries
tags: [priorities, ops]
timestamp: 2026-10-18T00:00:00Z
---

# Priorities (detail)

## Scratch-file git hygiene (surfaced 09-20; 268 tracked scratch files as of 10-04)
`rm` isn't granted so skills can't self-clean. Biggest offender: `output/.tmp-aeon-update/` (102 files, stale upstream clone + eyebrow dump from PR #232; safe to `git rm`). Also `output/.shiplog-*` (~15), `output/.tr-*`/`.gt-*`/`.ds-*` from token-report, `.tmp-sw/`, `.tmp_td/`, `.tw-*`. Needs skill-repair: `git rm` dead scratch and give each skill a `.gitignore`d scratch dir.

## secured-watch
Disabled (`enabled: false`) since ~09-30/10-01 with no logged operator decision (14+ days). Re-enable only after fixing the empty `note` parser (tooltip span). Needs operator decision.

## Health-issue auto-close
Open health issues as of 10-15: #230 token-report, #231 secured-watch, #234 tweet-digest (hype-adjacent), #247 aeon-update, #248 heartbeat, #258 changelog (10-12, unverifiable_claim: npm ci/tsc/build not run), #261 holdings (10-15). All stale vs. current green runs. Needs recovery-triggered auto-close.

## Re-enable extras
`fetch-tweets`, `tweet-allocator` only when organic signal justifies it.

## minitor
#72-#81 merged. SECURITY.md present at `.github/SECURITY.md`. Remaining: manifest.ts + ci.yml improvements (MED), README Deploy section (MED). 17 stars / 4 forks.

## aeon framework state
v0.1.0 released 2026-07-10. docs-sync (changelog push-to) last ran 10-12 (aeon-website PR #627, 27 PRs #1167-#1196). Treat the website's `app/changelog-data.ts` as source of truth for what's published. Idempotency gap found 10-05 (#1093 missed) - cross-check every merged PR against `number:` entries on each push-to run. Latest shiplog 10-05→10-12: 27 PRs, headline = two external contributors' skill packs (Epoch, bon travail) merged (#1167/#1168), 19 MCP-marketplace/awesome-list PRs (3 merged); aeon 771 stars (+6). Prior window 09-28→10-05 headline: Aeon Connect hosted onboarding. Articles: `output/articles/shiplog-2026-10-12.md`, `changelog-2026-10-08.md`.

## repo-pulse (10-12, complete window)
aeon 771★/280 forks (+6/+3); soul.md 688★/75; opendia 1927★/161 (-2 forks); minitor 17★/4. All STEADY. Truncation risk remains (see lessons).

## aeon-agent fork sync (aeon-update)
Baseline `df013db` after PR #259 (10-12, 27 commits, 184 files). PR #268 (10-17, `df013db..3a747cd`, 42 commits, 90 files applied, 29 pending conflicts incl. 12 ci-*.yml runs-on overrides; new skill `anatomy` held back - generators/eyebrow can't run headless) is open/unmerged as far as logs show. Earlier conflicts carried: `.github/README.md`, `.github/workflows/aeon.yml` (ships apt-hang + snapshot fixes - hand-merge worth it), `CHANGELOG.md`, `llms.txt`, `docs/examples/README.md`, `docs/skill-packs.md`, `skills/shiplog/SKILL.md`. Catalog 91 skills.

## Working tree anomaly
`AGENTS.md` deleted (uncommitted) and `notify`, `notify-jsonrender`, `secretcurl` untracked since at least 2026-08-18 (60+ days), re-created runner-side each run. Risk: a `git add -A` lands the deletion. Needs decision: restore, delete-and-commit, or gitignore.
