#!/bin/bash
# classify upstream-changed files: base=3a747cd head=75f3b55
B=3a747cd035152c4556944d5ce60be0a3198670fb
H=75f3b55b50d895eaf101c511e91e5fa921e20075
gh api repos/aeonfun/aeon/compare/$B...$H --jq '.files[] | "\(.status)\t\(.filename)"' > /tmp/files.tsv
OUT=/tmp/aeon-update-class.tsv
: > "$OUT"
while IFS=$'\t' read -r st f; do
  case "$f" in
    aeon.yml|STRATEGY.md|soul/*|memory/*|output/*|.mcp.json|eyebrowlock.json|catalog/skills.json|catalog/packs.json|catalog/skill-icons.json) echo -e "OPERATOR\t$f" >> "$OUT"; continue;;
  esac
  if [ "$st" = added ]; then
    if [ -e "$f" ]; then echo -e "CONFLICT\t$f" >> "$OUT"; else echo -e "CLEAN-ADD\t$f" >> "$OUT"; fi; continue
  fi
  if [ ! -e "$f" ]; then echo -e "CONFLICT-absent\t$f" >> "$OUT"; continue; fi
  lh=$(sha256sum < "$f" | cut -d' ' -f1)
  hh=$(git show "$H:$f" | sha256sum | cut -d' ' -f1)
  bh=$(git show "$B:$f" | sha256sum | cut -d' ' -f1)
  if [ "$lh" = "$hh" ]; then echo -e "SKIP\t$f"
  elif [ "$lh" = "$bh" ]; then echo -e "CLEAN-UPDATE\t$f"
  else
    d=$(mktemp -d)
    git show "$B:$f" > $d/base; git show "$H:$f" > $d/head; cp "$f" $d/local
    if git merge-file -p --diff3 $d/local $d/base $d/head > $d/merged 2>/dev/null; then
      mkdir -p /tmp/merged/$(dirname "$f"); cp $d/merged /tmp/merged/$f
      echo -e "CLEAN-MERGE\t$f"
    else echo -e "CONFLICT\t$f"; fi
  fi >> "$OUT"
done < /tmp/files.tsv
cat "$OUT"
