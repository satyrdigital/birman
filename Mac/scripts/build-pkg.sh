#!/usr/bin/env bash
set -euo pipefail

# Native all-users macOS installer; neither the legacy DMG nor third-party tools are used.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/Mac/src/UkrainianTypographicLayouts.bundle"
OUT_DIR="${1:-$ROOT/dist}"
VERSION="2.0.0"
BUNDLE_NAME="$(basename "$SRC")"
DEST="Library/Keyboard Layouts/$BUNDLE_NAME"

for tool in pkgbuild iconutil swift xmllint plutil ditto pkgutil; do
  command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 1; }
done
test -d "$SRC/Contents/Resources"
plutil -lint "$SRC/Contents/Info.plist" "$SRC/Contents/version.plist"

count=0
while IFS= read -r -d '' layout; do
  xmllint --nonet --noout "$layout"
  count=$((count + 1))
done < <(find "$SRC/Contents/Resources" -name '*.keylayout' -type f -print0)
if [[ "$count" -ne 5 ]]; then
  echo "Expected 5 .keylayout sources, found $count" >&2
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
STAGING="$WORK/root"
mkdir -p "$STAGING/Library/Keyboard Layouts" "$OUT_DIR"
ditto "$SRC" "$STAGING/$DEST"

# Render neutral "RU" .icns (not a country flag) from auditable Swift source.
ICON="$STAGING/$DEST/Contents/Resources/Russian (Typographic + Ukrainian).icns"
swift "$ROOT/Mac/scripts/render-neutral-icon.swift" "$ICON"
test -s "$ICON"

PACKAGE="$OUT_DIR/Birman-Typographic-Layouts-macOS-$VERSION.pkg"
pkgbuild \
  --root "$STAGING" \
  --identifier "com.satyrdigital.birman.typographic-layouts" \
  --version "$VERSION" \
  --install-location "/" \
  --ownership recommended \
  "$PACKAGE"

pkgutil --expand "$PACKAGE" "$WORK/expanded"
test -s "$WORK/expanded/PackageInfo"
pkgutil --payload-files "$PACKAGE" | grep -F 'UkrainianTypographicLayouts.bundle'
shasum -a 256 "$PACKAGE"

echo "Built: $PACKAGE"
echo "Installs to: /Library/Keyboard Layouts/$BUNDLE_NAME"
echo "This unsigned local package may require user confirmation."
echo "Log out/in after installation, then enable the new layout in System Settings."
