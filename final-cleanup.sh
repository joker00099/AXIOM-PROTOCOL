#!/usr/bin/env bash
set -euo pipefail

# final-cleanup.sh - Scan and optionally replace legacy 'red-flag' phrases.
# Usage: ./final-cleanup.sh [--apply] [--replace-qubit]
# --apply: perform in-place replacements (default is dry-run)
# --replace-qubit: replace 'Qubit' with 'AXIOM' (DANGEROUS: may break code)

APPLY=false
REPLACE_QUBIT=false

for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=true ;; 
    --replace-qubit) REPLACE_QUBIT=true ;;
    *) echo "Unknown arg: $arg" ;;
  esac
done

ROOT_DIR=$(pwd)
EXCLUDE="--exclude-dir=.git --exclude-dir=target --exclude-dir=target/"

echo "Scanning repository for red-flag phrases (dry run unless --apply supplied)"

PHRASES=(
  "500x"
  "1000x"
  "potential return"
  "ROI"
  "investment"
  "price prediction"
  "\bmoon\b"
  "profit"
)

# Show occurrences
for p in "${PHRASES[@]}"; do
  echo -e "\n--- Matches for: '$p' ---"
  grep -RIn --binary-files=without-match -E "$p" . $EXCLUDE || true
done

# Replacement target text
REPLACEMENT="Mathematical scarcity; provable supply cap; verifiable economics; fixed-supply protocol"

if [ "$APPLY" = true ]; then
  echo "\nApplying replacements..."
  # Use perl for better regex handling and in-place editing across files
  for p in "${PHRASES[@]}"; do
    echo "Replacing occurrences of '$p' with standardized phrasing"
    # Skip binary files
    perl -0777 -pe "s/$p/$REPLACEMENT/gi" -i $(grep -RIl --binary-files=without-match -E "$p" . $EXCLUDE) || true
  done
  echo "Replacements applied."
else
  echo "\nDry run complete. Re-run with --apply to modify files."
fi

# Qubit/AXIOM scan
echo "\nScanning for 'Qubit' and 'QBT' references (for manual review)"
grep -RIn --binary-files=without-match "Qubit" . $EXCLUDE || true
grep -RIn --binary-files=without-match "\bQBT\b" . $EXCLUDE || true

if [ "$REPLACE_QUBIT" = true ]; then
  echo "\n--replace-qubit specified: Replacing literal 'Qubit' -> 'AXIOM' (CAUTION)"
  if [ "$APPLY" = true ]; then
    perl -0777 -pe "s/\bQubit\b/AXIOM/g" -i $(grep -RIl --binary-files=without-match "\bQubit\b" . $EXCLUDE) || true
    perl -0777 -pe "s/\bQBT\b/AXM/g" -i $(grep -RIl --binary-files=without-match "\bQBT\b" . $EXCLUDE) || true
    echo "Qubit -> AXIOM replacements applied. Manually inspect code and filenames."
  else
    echo "Would replace Qubit -> AXIOM but --apply not supplied. Re-run with both flags."
  fi
fi

echo "\nFinal note: The script makes conservative automatic changes. Manually review all replacements before commit."
chmod +x final-cleanup.sh
