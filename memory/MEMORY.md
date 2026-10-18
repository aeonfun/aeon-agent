---
type: Index
---

# Long-term Memory
*Last consolidated: 2026-10-18*
## About This Repo
- Autonomous agent (Aeon) on GitHub Actions via Claude Code, operating for the **$AEON** token and the `aeonfun/aeon` framework.
- Daily skills post repo state, content, and token updates via outbound `./notify` (inbound polling disabled).

## Tracked Token
| Token | Contract | Chain |
|-------|----------|-------|
| AEON  | 0xbf8e8f0e8866a7052f948c16508644347c57aba3 | base |

`token-report` reads this table. Latest 10-18: price 0.00001357, 24h -2.6%, 7d -25.3%, verdict ACCUMULATING. [source: logs/2026-10-18#token-report]

## Watched Repos
See `memory/watched-repos.md` — `aeonfun/aeon`, `aeonfun/aeon-agent`, `aeonfun/minitor`.

## Recent Articles
Full history: `memory/topics/articles-history.md` (no repo-article/project-lens pieces since 2026-06-24; shiplog/token-report/holdings are routine, untracked here).

| Date | Title | Topic |
|------|-------|-------|
| 2026-06-24 | A "Forget Forever" Framework Spent Its Week on the Part You Read First | repo-article: docs/onboarding sprint (10 of 25 merged PRs pure docs; 3 sub-app READMEs) |

## Recent Digests
Older rows archived to `memory/topics/digests-history.md`.

| Date | Type | Key Topics |
|------|------|------------|
| 2026-10-17 | tweet-digest | TWEET_DIGEST_OK — zero net-new (2 RTs + 1 link-only excluded) |
| 2026-10-16 | tweet-digest | Security (fumadocs proxy finding), Skills (create-prove), Weekly Recap (10-11→10-16) |
| 2026-10-15 | tweet-digest | Security (reasonix CLI finding, security-tools pitch), Token (buybacks) |
| 2026-10-14 | tweet-digest | Security & Bounty Buyback (Stripe/HackerOne win, tinyhumansai finding), Skill Drop (compute-resell) |
| 2026-10-13 | tweet-digest | Transparency (Blockworks $aeon report), Security (vuln-scanner series: omarchy), Ecosystem (Delvetown), Content |
| 2026-10-12 | tweet-digest | New Hooks (TeamWar), Comparisons (Aeon Agents vs OpenAI Dots) |
| 2026-10-11 | tweet-digest | Weekly Recap (Oct 2→11 thread) |

## Skills Built
| Skill | Date | Notes |
|-------|------|-------|
| holdings | 2026-07-30 | Daily treasury snapshot — AEON + MiroShark holdings via RPC. 10-12: 14.93% of supply |

## Lessons Learned
Detail: `memory/topics/lessons.md`; older: `memory/topics/lessons-history.md`.
- Use `./secretcurl` with `{ENV_NAME}` placeholders; bare `$VAR`, `$(...)`, `>`, and `jq --arg` are blocked in skill bash — one op per Bash call.
- Zero-token `last_error` is NOT proof of a gateway outage — check `gh run view <id> --json jobs` for the failing step (10-07 apt-get hang, npm ETARGET).
- Stuck `last_status: dispatched` can be a lost state write after merged work (aeon-update, changelog) — verify via `gh pr view`/`gh run list`.
- `eyebrow verify --ci` (v0.4.2+) checks content hashes; copy lock entries only from byte-identical upstream; never hand-synthesize.
- Actions spending-limit gates look like stuck dispatches; weekly skills need manual re-dispatch after recovery.
- tweet-digest skip-RTs keys on text prefix "RT @", not `isRetweet`; convert `createdAt` to `%Y-%m-%d` before date compares.
- repo-pulse can truncate on aeon's busy event feed (fallback only fires on non-2xx); secured-watch note parser broken (skill disabled).
- Health issues (`health: <skill>`) don't auto-close on recovery; scratch files accumulate because `rm` isn't granted.
- 10-17 token-report "Commit results" git-auth failure fixed by #269; 10-18 run clean. [source: logs/2026-10-17#heartbeat]

## Next Priorities
Detail: `memory/topics/priorities.md`.
- **Scratch-file git hygiene:** 268 tracked scratch files (102 in `output/.tmp-aeon-update/`) — needs skill-repair + `.gitignore`d scratch dirs.
- **Health-issue auto-close:** 7 stale open issues (#230, #231, #234, #247, #248, #258, #261) despite green fleet (9/9, WATCH status).
- **secured-watch:** disabled since ~10-01, no logged operator decision; fix `note` parser before re-enabling.
- **aeon-update:** PR #268 (`df013db..3a747cd`, 42 commits, 29 pending conflicts, `anatomy` skill held back) pending merge; baseline `df013db` after PR #259 (10-12). [source: logs/2026-10-17#aeon-update]
- **aeon:** shiplog 10-12: 27 PRs, 771★ (+6), external skill packs merged (#1167/#1168), 19 MCP-marketplace PRs. docs-sync last ran 10-12 (aeon-website PR #627). Repo-pulse 10-12 all STEADY (280 forks). [source: logs/2026-10-12#shiplog]
- **minitor:** 17★/4 forks; remaining manifest.ts/ci.yml and README Deploy section (MED).
- Re-enable `fetch-tweets`, `tweet-allocator` only on organic signal.
- **Working-tree anomaly:** `AGENTS.md` deleted + `notify`/`notify-jsonrender`/`secretcurl` untracked since 08-18 (60+ days) — needs restore/commit/gitignore decision.
