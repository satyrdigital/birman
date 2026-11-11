#!/usr/bin/env bash
set -euo pipefail

# Native all-users macOS installer; neither the legacy DMG nor third-party tools are used.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/Mac/src/UkrainianTypographicLayouts.bundle"
OUT_DIR="${1:-$ROOT/dist}"
VERSION="2.0.0"
BUNDLE_NAME="$(basename "$SRC")"
DEST="Library/Keyboard Layouts/$BUNDLE_NAME"

for tool in pkgbuild iconutil swift python3 plutil ditto pkgutil; do
  command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 1; }
done
test -d "$SRC/Contents/Resources"
plutil -lint "$SRC/Contents/Info.plist" "$SRC/Contents/version.plist"

# Legacy Ukelele files are XML 1.1 and include numeric references to control
# characters. libxml2/xmllint treats those as XML 1.0 invalid references.
# Parse a validation-only in-memory copy, preserving the exact source payload.
python3 - "$SRC/Contents/Resources" <<'PY'
import pathlib, re, sys, xml.etree.ElementTree as ET
paths = sorted(pathlib.Path(sys.argv[1]).glob("*.keylayout"))
if len(paths) != 5:
    raise SystemExit(f"Expected 5 keyboard layouts, found {len(paths)}")
for path in paths:
    data = path.read_text(encoding="utf-8-sig")
    if not data.lstrip().startswith('<?xml version="1.1"'):
        raise SystemExit(f"Expected XML 1.1 in {path}")
    data = re.sub(r'&#(?:x0*(?:[0-8BCEF]|1[0-F])|0*(?:[0-8]|11|12|1[4-9]|2[0-9]|3[01]));', 'X', data, flags=re.I)
    root = ET.fromstring(data)
    if root.tag != "keyboard" or root.find("layouts") is None:
        raise SystemExit(f"Invalid keyboard structure: {path}")
print(f"Validated {len(paths)} legacy keylayout structures without modifying source files")
PY

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
