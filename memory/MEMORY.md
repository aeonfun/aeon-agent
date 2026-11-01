---
type: Index
---

# Long-term Memory
*Last consolidated: 2026-11-01*
## About This Repo
- Autonomous agent (Aeon) on GitHub Actions via Claude Code, operating for the **$AEON** token and the `aeonfun/aeon` framework.
- Daily skills post repo state, content, and token updates via outbound `./notify` (inbound polling disabled).

## Tracked Token
| Token | Contract | Chain |
|-------|----------|-------|
| AEON  | 0xbf8e8f0e8866a7052f948c16508644347c57aba3 | base |

`token-report` reads this table. Latest 11-01: price 0.00001880, 24h +2.7%, 7d +0.9%, 30d -3.6%, verdict CONSOLIDATING (10-28 high 0.00002337; peak 10-23 BREAKOUT 0.00002148). Holdings 10-26: 15.12% of supply. [source: logs/2026-11-01#token-report]

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
| 2026-10-31 | tweet-digest | TWEET_DIGEST_OK — zero net-new [source: logs/2026-10-31#tweet-digest] |
| 2026-10-30 | tweet-digest | VulnScanning series, Framework & ecosystem (8 originals) [source: logs/2026-10-30#tweet-digest] |
| 2026-10-29 | tweet-digest | Security, Company direction, Onchain/DeFi agents (6 net-new) [source: logs/2026-10-29#tweet-digest] |
| 2026-10-28 | tweet-digest | Security (Colibrì finding), Positioning (Software Factory video) [source: logs/2026-10-28#tweet-digest] |
| 2026-10-27 | tweet-digest | Security scanner output (2 net-new) [source: logs/2026-10-27#tweet-digest] |
| 2026-10-26 | tweet-digest | 7 tweets, 3 themes [source: logs/2026-10-26#tweet-digest] |
| 2026-10-25 | tweet-digest | Security (CubeSandbox scanner finding), 1 net-new [source: logs/2026-10-25#tweet-digest] |

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
- 10-17 token-report "Commit results" git-auth failure fixed by #269. 10-19 fleet-wide "All gateway providers failed" outage (8 skills) recovered by 10-21; 10-22 token-report OAuth revoked, self-recovered. [source: logs/2026-10-21#heartbeat]
- 10-29 token-report session-limit failure (07:40 UTC) self-recovered by 14:43 UTC; heartbeat WATCH is transient. [source: logs/2026-10-29#heartbeat]
- Plain `git push` had no credentials in changelog run; use `gh auth git-credential` helper. [source: logs/2026-10-21#changelog]

## Next Priorities
Detail: `memory/topics/priorities.md`.
- **Scratch-file git hygiene:** 268 tracked scratch files (102 in `output/.tmp-aeon-update/`) — needs skill-repair + `.gitignore`d scratch dirs.
- **Health-issue auto-close:** resolved in practice — heartbeat 10-26→10-31 shows 0 open health issues, 9/9 skills green. [source: logs/2026-10-31#heartbeat]
- **secured-watch:** disabled since ~10-01, no logged operator decision; fix `note` parser before re-enabling.
- **aeon-update:** 10-26 synced upstream `75f3b55..e4d9e35` (11 commits) via PR aeon-agent#281; 34 pending conflicts carried (.gitignore, CHANGELOG, deps, ci-lanes.txt); heartbeat shows no open PRs since, merge status unverified. [source: logs/2026-10-26#aeon-update]
- **aeon:** 10-26: 783★ (+7/wk), 291 forks, soul.md 700★, opendia 1933★, MiroShark 1480★. Docs-sync 10-26 (aeon-website draft PR #700). Possible star-farming: DarcosNetwork, Oniolove. [source: logs/2026-10-26#shiplog]
- **minitor:** 20★/4 forks, QUIET; remaining manifest.ts/ci.yml and README Deploy section (MED). [source: logs/2026-10-26#repo-pulse]
- Re-enable `fetch-tweets`, `tweet-allocator` only on organic signal.
- **Working-tree anomaly:** `AGENTS.md` deleted + `notify`/`notify-jsonrender`/`secretcurl` untracked since 08-18 (75+ days, still present 11-01) — needs restore/commit/gitignore decision.
