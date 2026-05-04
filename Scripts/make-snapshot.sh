#!/usr/bin/env bash
set -euo pipefail

# Projektrod = mappe over Scripts/
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PBX="$ROOT/Whist20.xcodeproj/project.pbxproj"

if [[ ! -f "$PBX" ]]; then
  echo "Fejl: forventede project.pbxproj i $PBX" >&2
  exit 1
fi

VER="$(grep -m1 'MARKETING_VERSION' "$PBX" | sed -n 's/.*MARKETING_VERSION = \([^;]*\);/\1/p' | tr -d ' ')"
if [[ -z "$VER" ]]; then
  echo "Fejl: kunne ikke læse MARKETING_VERSION" >&2
  exit 1
fi

DATE="${1:-$(date +%Y-%m-%d)}"
NAME="Whist20-${VER}-${DATE}"
DST="$ROOT/Snapshots/$NAME"

if [[ -e "$DST" ]]; then
  echo "Fejl: findes allerede: $DST" >&2
  exit 1
fi

mkdir -p "$ROOT/Snapshots"

echo "Opretter snapshot: $DST"
rsync -a \
  --exclude='Snapshots/' \
  --exclude='.DS_Store' \
  --exclude='**/xcuserdata/**' \
  "$ROOT/" "$DST/"

echo "Færdig. Åbn i Xcode: $DST/Whist20.xcodeproj"
