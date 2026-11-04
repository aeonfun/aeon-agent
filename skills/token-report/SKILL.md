---
type: Skill
name: token-report
category: crypto
description: Price performance report for the project's token — price, volume, liquidity, and context
var: ""
tags: [crypto]
mode: write
requires: [TWITTER_API_KEY, ALCHEMY_API_KEY?, XAI_API_KEY?, BASE_RPC_URL?]
capabilities: [external_api]
---
<!-- autoresearch: variation B — verdict-first template, threshold-based classification, true deltas from persistent STATE log, skip-when-empty sections -->

> **${var}** — Token contract address. If empty, uses tracked token from MEMORY.md.

## Config

This skill reads the token to track from the "Tracked Token" section in `memory/MEMORY.md`.

```markdown
## Tracked Token
| Token | Contract | Chain |
|-------|----------|-------|
| AEON  | 0xbf8e... | base |
```

If no tracked token is configured and `${var}` is empty, abort silently — no article, no notification.

Read the last 30 days of `memory/logs/*.md` for prior `TOKEN_REPORT_STATE:` lines (written in step 8). These are the authoritative source of 1d / 7d / 30d deltas, because a stored price yesterday beats an API window that shifts under you.

## Thesis

A daily token report is only useful if it tells the reader *what changed and whether it matters*. Snapshots of price, volume, and liquidity are table-stakes; the value is in the verdict. Every section below must either sharpen the verdict or be dropped. No filler, no "N/A", no "no specific context" sentences.

## Steps

### 1. Fetch core market data (GeckoTerminal — primary)

Save every response to a file and read only the fields you need: **never print a raw API body** (a whole token, pools, OHLCV or trades response is thousands of tokens that every later turn re-reads) and **fetch each URL once per run** (read a saved file again instead of refetching). Make the work folder first, as its own call (one allowed command per Bash call: no `VAR=` assignment, no `;`/`&&`/`||`, no `>` redirect into a file):
```bash
mkdir -p /tmp/token-report-work
```

The token and pools calls need only the contract: send both in one turn as two parallel calls, with the real contract in place of `CONTRACT_ADDRESS`:
```bash
curl -s --max-time 20 --retry 2 --retry-delay 3 -o /tmp/token-report-work/token.json -w 'gt token http=%{http_code} bytes=%{size_download}\n' "https://api.geckoterminal.com/api/v2/networks/base/tokens/CONTRACT_ADDRESS"
```
```bash
curl -s --max-time 20 --retry 2 --retry-delay 3 -o /tmp/token-report-work/pools.json -w 'gt pools http=%{http_code} bytes=%{size_download}\n' "https://api.geckoterminal.com/api/v2/networks/base/tokens/CONTRACT_ADDRESS/pools?page=1"
```
A fetch **failed** when it printed `bytes=0` or an `http=` other than 200. Then read each file with one literal `jq` call:
```bash
jq -c '.data.attributes | {symbol, name, price_usd, fdv_usd, market_cap_usd, total_reserve_in_usd, volume_h24: .volume_usd.h24}' /tmp/token-report-work/token.json
```
```bash
jq -c '.data[:3][] | .attributes | {address, name, price_usd: .base_token_price_usd, reserve_in_usd, volume_h24: .volume_usd.h24, change_h24: .price_change_percentage.h24, tx_h24: .transactions.h24}' /tmp/token-report-work/pools.json
```
Take the top pool's `address` and write it in place of `POOL_ADDRESS`, then fetch its candles and trades in one turn as three parallel calls:
```bash
curl -s --max-time 20 --retry 2 --retry-delay 3 -o /tmp/token-report-work/ohlcv-day.json -w 'gt ohlcv-day http=%{http_code} bytes=%{size_download}\n' "https://api.geckoterminal.com/api/v2/networks/base/pools/POOL_ADDRESS/ohlcv/day?aggregate=1&limit=30"
```
```bash
curl -s --max-time 20 --retry 2 --retry-delay 3 -o /tmp/token-report-work/ohlcv-hour.json -w 'gt ohlcv-hour http=%{http_code} bytes=%{size_download}\n' "https://api.geckoterminal.com/api/v2/networks/base/pools/POOL_ADDRESS/ohlcv/hour?aggregate=1&limit=24"
```
```bash
curl -s --max-time 20 --retry 2 --retry-delay 3 -o /tmp/token-report-work/trades.json -w 'gt trades http=%{http_code} bytes=%{size_download}\n' "https://api.geckoterminal.com/api/v2/networks/base/pools/POOL_ADDRESS/trades"
```
Candles come back as `[unix time, close, volume]` rows, newest first (one call per file, `ohlcv-day.json` then `ohlcv-hour.json`):
```bash
jq -c '.data.attributes.ohlcv_list | map([.[0], .[4], .[5]])' /tmp/token-report-work/ohlcv-day.json
```
Whale trades (`volume_in_usd >= 1000`), counted by side, with the 3 largest:
```bash
jq -c '[.data[].attributes | select((.volume_in_usd | tonumber) >= 1000) | {kind, usd: (.volume_in_usd | tonumber | floor), price_usd: ((select(.kind == "buy") | .price_to_in_usd) // .price_from_in_usd), time: .block_timestamp}] | {whales: length, whale_buys: (map(select(.kind == "buy")) | length), whale_sells: (map(select(.kind == "sell")) | length), top3: (sort_by(-.usd) | .[:3])}' /tmp/token-report-work/trades.json
```

If curl fails (sandbox block), retry each URL with **WebFetch**. If the token endpoint returns no data or 404 after both paths, go to step 9 with `TOKEN_REPORT_NO_DATA` — do not notify, do not write an article.

**Keep a fetch record for the Sources block.** For every endpoint in steps 1, 2, 2b and 6 (and the any page opened for the Context section) that actually returned data, note the full URL as called, with the real contract and pool address filled in, and the UTC time it answered (`date -u +%H:%M`). Step 5 prints exactly these as the article's sources. An endpoint that failed, was skipped or returned nothing usable is not a source.

### 2. Cross-check with DexScreener (sanity + alt signal)

```bash
curl -s --max-time 20 --retry 2 --retry-delay 3 -o /tmp/token-report-work/dexscreener.json -w 'ds http=%{http_code} bytes=%{size_download}\n' "https://api.dexscreener.com/latest/dex/tokens/CONTRACT_ADDRESS"
```
Send it in the same turn as the token and pools calls (it needs only the contract), then read the 3 deepest pairs:
```bash
jq -c '[.pairs[]? | {chainId, dexId, pairAddress, priceUsd, liquidity_usd: (.liquidity.usd // 0), volume_h24: .volume.h24, boosts: .boosts.active}] | sort_by(-.liquidity_usd) | .[:3]' /tmp/token-report-work/dexscreener.json
```

Use DexScreener for two things only:
- **Price sanity:** if DS price deviates >3% from GT price on the deepest-liquidity pair, mark `ds=divergent` in the sources footer and trust the deeper pool. Do not average.
- **Boost/trending flag:** if the pair is `boosted` or on `trending`, add one sentence to the Context section.

If DexScreener fails, continue with GT only (`ds=fail` in footer). Never abort on DS failure.

**Low-liquidity pair addendum:** the 3% deviation threshold above is calibrated for liquid pairs. On thin pairs it produces false `ds=divergent` flags from harmless tick noise. **If the pair's 24h volume is below $100k, raise the DS deviation threshold to 10% instead of 3%** before flagging `ds=divergent`. The deep-pool-wins rule still applies when the larger threshold is exceeded.

### 2b. Treasury wallets (on-chain liquidity)

If `memory/treasury-wallets.json` exists, fetch native-ETH balance for each entry on Base. This optional file declares the project's protocol wallets (treasury, deployer, etc.). If it's absent, skip this step (treasury reporting is off).

Check that the file exists with the Read tool (or a bare `ls memory/treasury-wallets.json`), then list the Base wallets with one literal `jq` call. No `VAR=` assignment, `[ -f ]` test, `&&` or `>` redirect: the run refuses each of those shapes.

```bash
jq -c '.wallets[] | select(.chain=="base")' memory/treasury-wallets.json
```

For each wallet line, query Base in this fallback order:

1. **Public Base RPC `eth_getBalance` (primary, keyless — the same endpoint the repo's other Base skills use):**
   Pick `<RPC_URL>` yourself: `BASE_RPC_URL` when it is set, else `https://mainnet.base.org`. One call per wallet, with the URL and the wallet address written in literally (an `RPC="..."` assignment is refused):
   ```bash
   curl -m 10 -s -X POST "<RPC_URL>" -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["ADDRESS","latest"],"id":1}'
   ```
   `https://mainnet.base.org` is the public, keyless Base JSON-RPC endpoint that `wallet-profile`, `tx-explain`, `lp-lock`, and `fund-flow` already default to; override with `BASE_RPC_URL` for an authenticated endpoint (append any key in the URL path, **never a `-H` header** — the sandbox blocks env-var expansion in headers). The static `-H "Content-Type: application/json"` carries no secret, so it is safe. Response is JSON-RPC `{"jsonrpc":"2.0","result":"0x<hex_wei>","id":1}`. Convert hex → decimal → ÷1e18. If the response has no `result`, the `result` is `null`/non-hex, or it carries an `error`, mark this wallet `eth=fetch_fail` and continue.

   > Why not Etherscan here: the legacy per-chain `api.basescan.org/api` host (BaseScan V1) is deprecated, and the unified `api.etherscan.io/v2` endpoint gates Base (`chainid=8453`) behind a paid plan (`"Free API access is not supported for this chain"`). Neither works keyless, so a plain JSON-RPC `eth_getBalance` is the reliable keyless path — matching `wallet-profile`/`tx-explain`.

2. **Alchemy (secondary, only if `ALCHEMY_API_KEY` is set AND the public RPC failed):** use `./secretcurl` with the literal `{ALCHEMY_API_KEY}` placeholder (never `$ALCHEMY_API_KEY` — the permission layer blocks any command text containing a secret expansion, URL path included; see CLAUDE.md → Network & Secrets):
   ```bash
   ./secretcurl -m 10 -s -X POST "https://base-mainnet.g.alchemy.com/v2/{ALCHEMY_API_KEY}" \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","id":1,"method":"eth_getBalance","params":["ADDRESS","latest"]}'
   ```
   Identical JSON-RPC shape and hex → decimal → ÷1e18 conversion as above.

3. **WebFetch fallback** (sandbox block on either curl): retry the same POST with **WebFetch** before declaring `fetch_fail`.

Compute, per wallet:
- `eth_balance` — decimal ETH, 4 decimals.
- `eth_balance_delta_24h` — diff vs yesterday's `TREASURY_STATE:` log line (omit when prior is missing).

Aggregate:
- `treasury_eth_total` — sum across **role=treasury** wallets only (deployer wallets are operational, not protocol funds).
- `treasury_low_alert` — `true` if `treasury_eth_total < 0.01` AND `treasury_eth_total > 0` (a zero balance is a config error, not a depletion; do not alarm).

If `memory/treasury-wallets.json` is missing or contains no `chain=base` entries, set `treasury=skip` in the sources footer and OMIT the Treasury subsection from the article + notification. Do not invent the section.

### 3. Compute true deltas

From the `TOKEN_REPORT_STATE:` key=value lines in prior logs, load:
- **1d-ago price, liquidity, volume_24h, buys, sells, whales** (yesterday's run)
- **7d-ago price**
- **30d-ago price** (fall back to GT daily OHLCV close if missing)

For each:
- If prior value exists, compute pct delta against it.
- If prior is missing, compute from OHLCV candles and mark the figure `(~7d)` or `(~30d)` to signal the fallback source.

Derived signals:
- **Liq Δ 24h:** pct change vs yesterday's stored liquidity.
- **Vol ratio:** today's 24h volume ÷ mean(last 7 days of 24h volume). Report as `Z.Z×`.
- **Buy/sell shift:** (today_buys/today_sells) vs yesterday's ratio. Report both.
- **Whale trades 24h:** count of single trades with `volume_in_usd >= 1000` in the trades feed. List the top 3 with direction and size in the "What changed" section if ≥1 exists.

### 4. Classify the day (one verdict)

Pick exactly one label from the table. Thresholds use *today's true deltas* from step 3. Evaluate top-to-bottom; the first row whose trigger fully matches wins.

| Label | Trigger |
|-------|---------|
| `BREAKOUT` | Δprice ≥ +10% AND vol ratio ≥ 2.0 |
| `BREAKDOWN` | Δprice ≤ −10% AND vol ratio ≥ 2.0 |
| `RALLYING` | Δprice ≥ +3% AND (vol ratio ≥ 1.0 OR Δprice ≥ +10%) |
| `SLIDING` | Δprice ≤ −3% AND (vol ratio ≥ 1.0 OR Δprice ≤ −10%) |
| `ACCUMULATING` | abs(Δprice) < 3% AND buy/sell ratio ≥ 1.3 AND whale buys ≥ 1 |
| `DISTRIBUTING` | abs(Δprice) < 3% AND buy/sell ratio ≤ 0.7 AND whale sells ≥ 1 |
| `QUIET` | vol ratio < 0.5 AND whale trades = 0 |
| `CONSOLIDATING` | (everything else) |

A move of 10% or more always lands on BREAKOUT/BREAKDOWN (vol ratio 2.0 or more) or RALLYING/SLIDING (any lower vol ratio), never on QUIET or CONSOLIDATING.

Do not freelance labels. The verdict drives the lede, the TL;DR, and the notification. Explain the verdict through its numbers and thresholds (`+12.4% on 1.6x volume`); never mention this table, its steps or a missing row in the article or notification.

### 5. Compile the report

Save to `output/articles/token-report-${today}.md`:

```markdown
# $TOKEN — ${today}

**Verdict:** [LABEL] — [≤18 words, citing the 1–2 numbers that drove the label]

## 24h at a glance

| Metric | Now | 24h Δ | vs 7d avg |
|--------|-----|-------|-----------|
| Price | $X.XXXX | ±Y.Y% | — |
| Liquidity | $X.XK | ±Y.Y% | — |
| Volume (24h) | $X.XK | — | Z.Z× |
| Buys / Sells | X / Y | ratio Z.ZZ (yest Z.ZZ) | — |
| Whale trades (≥$1k) | N | — | — |
| FDV | $X.XM | — | — |

## Trend
- **7d:** ±X.X% ([one phrase: rallying, range-bound, rolling over, etc.])
- **30d:** ±X.X% ([one phrase])

## Treasury
[Include ONLY if step 2b returned at least one wallet with a real balance. One row per wallet, role-sorted (treasury first, then deployer, then other). If `treasury_low_alert` is true, lead the section with one sentence naming the floor that was crossed.]

| Wallet | Role | ETH | 24h Δ |
|--------|------|-----|-------|
| 0xf1e9…158e | treasury | X.XXXX | ±Y.YY |
| 0x6797…e3a2 | deployer | X.XXXX | ±Y.YY |

## What changed
[2–4 sentences. Name the specific deltas that matter and the verdict they produced. If whale trades exist, list the top 3 as `buy $1.2K @ $0.0042 · 11:03 UTC`. If liquidity moved >5%, name the pool and the $ amount. Tie every sentence back to the verdict. No filler.]

## Social Pulse
[Only include if the social fetch (Step 6) returns >=2 tweets with >=10 engagement (step 6 sets `xai=ok`). Lead with a one-line read of the conversation shape, then quote 1-3 tweets with @handle + engagement counts + the tweet link from that response. Otherwise OMIT this section entirely.]

## Context
[Only include when there is a genuine link to known activity: a recent repo release, a broader market regime shift, a boost/trending flag, an on-chain event. Each claim comes from something this run fetched and lists under Sources (the DexScreener boost flag, the trades feed, a release page opened this run). Cite an X post, tweet or @handle only when step 6 set `xai=ok` and that post is in its response; on `xai=skip` or `xai=fail`, no x.com links and no X-sourced claims anywhere in the article. Facts recalled from memory or old logs with no URL fetched this run stay out. If none, OMIT. Never write "no specific context".]

---
*Chart: https://www.geckoterminal.com/base/pools/POOL_ADDRESS*
*Contract: CONTRACT_ADDRESS | Chain: Base*

**Sources** (fetched ${today}, times UTC)
- GeckoTerminal token: https://api.geckoterminal.com/api/v2/networks/base/tokens/CONTRACT_ADDRESS (HH:MM)
- GeckoTerminal pools: https://api.geckoterminal.com/api/v2/networks/base/tokens/CONTRACT_ADDRESS/pools?page=1 (HH:MM)
- GeckoTerminal OHLCV: https://api.geckoterminal.com/api/v2/networks/base/pools/POOL_ADDRESS/ohlcv/day?aggregate=1&limit=30 and https://api.geckoterminal.com/api/v2/networks/base/pools/POOL_ADDRESS/ohlcv/hour?aggregate=1&limit=24 (HH:MM)
- GeckoTerminal trades: https://api.geckoterminal.com/api/v2/networks/base/pools/POOL_ADDRESS/trades (HH:MM)
- DexScreener: https://api.dexscreener.com/latest/dex/tokens/CONTRACT_ADDRESS (HH:MM) [price within X.X% of GeckoTerminal | diverged X.X%, deeper pool used]
- Treasury balances: eth_getBalance on https://RPC_HOST for N wallets (HH:MM)
- X search: https://api.twitterapi.io/twitter/tweet/advanced_search (query, N tweets kept) (HH:MM) [or https://api.x.ai/v1/responses (x_search fallback)]
- Prior values: TOKEN_REPORT_STATE lines in memory/logs/ (1d: YYYY-MM-DD, 7d: YYYY-MM-DD, 30d: YYYY-MM-DD or daily OHLCV)
- Not used: X search (no key | under 2 tweets cleared the bar | API error) · treasury (not configured | fetch failed) · DexScreener (fetch failed)
```

**Sources block rules:**
- One line per source this run actually used, taken from the fetch record (step 1): the full URL as called, contract and pool filled in, plus the UTC time it answered. Drop every template line for a source that was not used, and add a line for any extra URL (release page) a claim relies on.
- The `Not used:` line names, in plain words, each skipped or failed source and why; omit it when every source answered. Never write the short status codes (`gt=ok`, `xai=skip`) in the article: they stay in the step 8 log line.
- Never print a secret. For Alchemy, or a `BASE_RPC_URL` that carries a key, write only `https://<host>` and `(key hidden)`. Never print a `{...}` placeholder or an Authorization value.

**Section discipline:**
- If Social Pulse or Context has no real content, drop the section — do not write placeholder text.
- Never round in a way that flips a sign or crosses a threshold (e.g. don't render `−0.05%` as `0.0%`).
- Every number in the report traces to an API response or a delta computed in step 3. Do not invent figures.
- Every claim outside the tables traces to a line in the Sources block. A claim with no fetched source is dropped.
- When a figure is compared to a verdict threshold, give the threshold number (e.g. `ratio 1.13, under the 1.3 accumulation bar`). Every trade time not from today carries its date: `HH:MM UTC (MM-DD)`.

### 6. Social sentiment (conditional)

**Path A - twitterapi.io (primary).** Structured tweet objects with exact engagement counts and real permalinks - no fabrication risk, ~700ms. Search the last 24h for the ticker or contract, then keep tweets clearing the engagement bar. Auth via `./secretcurl` with the literal `{TWITTER_API_KEY}` placeholder (never `$TWITTER_API_KEY`; see CLAUDE.md -> Network & Secrets):

First `date -u +%Y-%m-%d` (prints TODAY) and `date -u -d '1 day ago' +%Y-%m-%d` (prints SINCE), each as its own call. Then one call with the ticker, contract and both dates written in literally (no `VAR=$(...)`, no `$` on the line):

```bash
./secretcurl -s -o /tmp/tw-token.json -w 'twitterapi http=%{http_code} bytes=%{size_download}\n' -G "https://api.twitterapi.io/twitter/tweet/advanced_search" \
  --data 'query=%24<TICKER>%20OR%20CONTRACT_ADDRESS%20since:<SINCE>%20until:<TODAY>' --data 'queryType=Latest' -H "X-API-Key: {TWITTER_API_KEY}"
```

`%24` is the cashtag `$`, sent already URL-encoded (spaces as `%20`) so no `$` lands on the command line, where it reads as a shell expansion and is refused. `<TICKER>` is the bare tracked ticker (e.g. `AEON`), `CONTRACT_ADDRESS` the token address. On HTTP 200, keep tweets with >=10 engagement, top 5 by likes, in one literal `jq` call:

```bash
jq -r '[.tweets[] | select((.likeCount + .retweetCount + .replyCount) >= 10)] | sort_by(-.likeCount) | .[:5][] | [.author.userName, .likeCount, .retweetCount, .replyCount, .url, .text] | @tsv' /tmp/tw-token.json
```

On `HTTP=200` with >=2 tweets clearing the bar, build the Social Pulse section, exclude obvious bots and generic shill posts, and set `xai=ok` in the footer.

**Path B - xAI Grok `x_search` (fallback).** Only if Path A returned non-2xx, empty, timed out, or `TWITTER_API_KEY` is not on the run notes' "Keys set for this run" line. Call it **in-run** with `./secretcurl` and the literal `{XAI_API_KEY}` placeholder (never `$XAI_API_KEY`; see CLAUDE.md -> Network & Secrets). Build the body with a literal `jq -n` filter, the ticker and contract written in, and pipe it straight into the send in one call:

```bash
jq -n '{model:"grok-4-1-fast", input:[{role:"user",content:"Search X for the TICKER cashtag or CONTRACT_ADDRESS mentions in the last 24 hours with at least 10 likes. Return up to 5 notable tweets with @handle, engagement counts, and a one-line summary of the claim or vibe. Exclude obvious bots and generic shill posts."}], tools:[{type:"x_search"}]}' \
  | ./secretcurl -s -X POST "https://api.x.ai/v1/responses" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {XAI_API_KEY}" \
  --data-binary @-
```

If neither path returns at least 2 tweets that clear the engagement bar, skip the Social Pulse section and set `xai=skip`. On API error on both paths, set `xai=fail` and skip. If neither `TWITTER_API_KEY` nor `XAI_API_KEY` is on the run notes' "Keys set for this run" line, set `xai=skip` (never test a key with a shell command: those calls are refused). Only `xai=ok` adds the X search line to the Sources block; on `skip` or `fail` it goes on the `Not used:` line, and the article cites no X post at all (not in Social Pulse, Context or What changed), even one found some other way.

### 7. Save article

Write the compiled report to `output/articles/token-report-${today}.md`.

### 8. State log (powers tomorrow's deltas)

Append to `memory/logs/${today}.md`:

```
### token-report
- Verdict: [LABEL]
- TOKEN_REPORT_STATE: price=X.XXXX liquidity=XXXX.XX volume_24h=XXXX.XX buys=N sells=N whales=N pool=POOL_ADDRESS
- TREASURY_STATE: treasury_eth_total=X.XXXX wallets=N (one TREASURY_WALLET_STATE line per wallet below)
- TREASURY_WALLET_STATE: addr=0xf1e9…158e role=treasury eth=X.XXXX
- TREASURY_WALLET_STATE: addr=0x6797…e3a2 role=deployer eth=X.XXXX
- 24h: ±X.X% | 7d: ±X.X% | 30d: ±X.X%
- Article: output/articles/token-report-${today}.md
- Sources: gt=ok ds=[ok|fail|divergent] xai=[ok|skip|fail] treasury=[ok|skip|fetch_fail]
```

The `TOKEN_REPORT_STATE:` line is a contract — step 3 of the next run parses it with a key=value split. Keep the keys, order, and numeric formats stable. No currency symbols, no thousands separators. The `TREASURY_WALLET_STATE:` lines (one per fetched wallet) feed step 2b's 24h delta — parse them with the same key=value split, keyed on `addr`. Omit `TREASURY_STATE` and `TREASURY_WALLET_STATE` lines entirely on `treasury=skip` runs so a wallets.json that disappears later doesn't leave stale balances in the log.

### 9. Notify

Lead with the verdict, not raw numbers. One short paragraph plus metrics.

```
*$TOKEN — [LABEL]*

[One sentence citing the driving number(s).]

Price $X.XXXX (±Y.Y% 24h) | Liq $X.XK (±Z.Z%) | Vol $X.XK (W.W× 7d)
Buys/Sells X/Y (ratio Z.ZZ) | Whales: N
Treasury: X.XXXX ETH (±Y.YY 24h)

Chart: https://www.geckoterminal.com/base/pools/POOL_ADDRESS
```

The `Treasury:` line is included ONLY when step 2b populated treasury_eth_total > 0. Omit the line entirely on `treasury=skip` / `treasury=fetch_fail` runs — silence beats a misleading number.

**Skip rules:**
- `TOKEN_REPORT_NO_DATA` (step 1 bailout): log only, **no notification, no article**.
- `QUIET` verdict with whales=0 AND abs(Δprice 24h) <1%: send a single-line notification `$TOKEN quiet — $X.XXXX flat, vol $X.XK.` (no table). This confirms the skill ran without pinging channels with filler on dead days. **Exception:** if `treasury_low_alert` is true, override QUIET and send the full notification with a leading `*Treasury gas reserve low — X.XXXX ETH on treasury, floor 0.01 ETH.*` line. A token going quiet on a day when the agent can no longer pay for gas is the exact regime where the operator needs to see it.
- Any other verdict: full notification above.

**Treasury alert (independent of verdict):** if `treasury_low_alert` is true on any run, prepend this line to the notification body — even on QUIET, even on CONSOLIDATING:

```
⚠️ *Treasury gas reserve low — X.XXXX ETH on treasury (floor 0.01 ETH).*
```

## Sandbox note

Public reads (GeckoTerminal, DexScreener, the keyless Base RPC `mainnet.base.org`) use plain `curl`; on a real failure (non-2xx / timeout / empty), retry with **WebFetch** - it accepts the JSON body for the `eth_getBalance` POST. The auth'd calls (Alchemy fallback, twitterapi.io + api.x.ai Social Pulse) run **in-run** via `./secretcurl` with `{ALCHEMY_API_KEY}` / `{TWITTER_API_KEY}` / `{XAI_API_KEY}` placeholders - no pre-fetch / post-process plumbing.

The Alchemy fallback in step 2b puts the key in the URL path through `./secretcurl`'s `{ALCHEMY_API_KEY}` placeholder; a bare `$ALCHEMY_API_KEY` on the line (even inside the URL) is refused, so never inline it. If Alchemy is unset, skip silently — the keyless public RPC + WebFetch are enough.

## Constraints

- Never invent numbers. Every figure traces to an API response or a computed delta.
- Never write filler sections. Drop them.
- The article's Sources block lists full URLs plus UTC fetch times for the sources used, never bare status codes. No X citation unless step 6 returned `xai=ok`.
- Verdict must come from the step-4 table — no freelance labels.
- On `TOKEN_REPORT_NO_DATA`, exit silently. No notification about the failure.
- Preserve the `TOKEN_REPORT_STATE:` log line schema — tomorrow's run depends on it.
- Preserve the `TREASURY_WALLET_STATE:` log line schema (one line per fetched wallet, keyed on `addr`) — step 2b's 24h delta depends on it.
- A treasury fetch failure is not a token-report failure. On `treasury=fetch_fail`, omit the Treasury subsection + notification line but still write the full token report — the token data is the primary product, treasury is an annotation.
- Wallets with `role` outside {`treasury`, `deployer`} appear in the article table sorted last under "other"; only `role=treasury` wallets count toward `treasury_eth_total` and the low-balance alert.
