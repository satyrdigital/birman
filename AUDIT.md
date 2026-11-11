# Modernization and security audit

Status: **work in progress**. This fork is maintained for personal use.

## Scope

1. macOS first: neutral, flag-free Russian + Ukrainian layout, current macOS compatibility, built-in shortcuts.
2. Windows next: rebuild layout DLL/MSI from inspected source, clean installer, Windows 11 testing.
3. Linux last: replace the legacy system-file patching installer with safe and reversible installation.

## Findings from the inherited repository

| Severity | Area | Observation | Action |
| --- | --- | --- | --- |
| High | Ubuntu | `Ubuntu/install.sh` replaces the system `evdev.xml` file using a temporary file, removes the original before moving the replacement, and uses an obsolete `envdev.xml` filename. Risk of breaking keyboard configuration. | Do not run inherited installer; replace before Linux rollout |
| Medium | Windows | Distributions include precompiled `.exe`, `.msi`, and `.dll` files. No reproducible build pipeline or signatures are documented. | Treat binaries as **unverified**, rebuild and test from `.klc` sources before use |
| Medium | macOS | The distributed `.dmg` is a legacy artifact. Changes to source bundle **do not update the DMG**. | For testing, install the source `.bundle`; do not use the old DMG |
| Low | macOS | The Russian + Ukrainian keyboard layout included a flag icon resource. | Remove icon resource; check actual menu appearance on the target macOS |
| Informational | macOS | Source uses declarative `.keylayout` XML and `.plist` configuration; no executable payload appears in the source bundle. | Static source review only; dynamic inspection and OS testing pending |
| Informational | Legal | No explicit license file was present in the inherited repository as inspected. | Keep attribution; do not assume public redistribution rights |

**Not an all-clear:** checking source files and repository structure does not prove that binaries are safe. Binary analysis, dependency review, fresh builds, signature inspection, and real-device regression tests remain to be done.

## macOS installation from source (for testing)

1. Download this branch as ZIP and extract it.
2. Find `Mac/src/UkrainianTypographicLayouts.bundle`.
3. Copy the whole bundle to `~/Library/Keyboard Layouts/`. Create the directory if absent.
4. Log out and back in (or restart).
5. Open **System Settings → Keyboard → Text Input → Edit**; select **Russian (Typographic + Ukrainian)**.
6. Remove the older duplicate layout entry, if present, *after* confirming the new entry works.
7. Test standard Russian keys; press **right Option** for Ukrainian `і`, `ї`, `є`, `ґ`.

If a flag remains in the input source menu, note that the icon may originate from macOS language-based defaults rather than this repo's resource. This requires a neutral replacement icon or further testing; **the desired flagless appearance is not yet verified**.

On Apple keyboards the key is **Option (⌥)**; on a typical PC keyboard connected to a Mac, the equivalent physical key is **Alt**. The keyboard definition supports Option modifiers but cannot itself change global input-source switching shortcuts. Configure those in macOS **System Settings → Keyboard → Keyboard Shortcuts → Input Sources**; `Ctrl+Shift` may conflict with other shortcuts and availability must be tested on the installed macOS release.

## Compatibility matrix

| Platform | Source present | Tested |
| --- | --- | --- |
| Windows 11 x64 | Yes (`.klc`) | Existing installation used, reproducible build audit pending |
| Current Apple Silicon macOS | Yes (`.bundle`) | Not yet validated on target |
| Ubuntu 26.04 LTS | Yes (XKB) | Not tested; inherited installer unsafe to run |

## Validation checklist

- [ ] Flagless menu indicator confirmed on current macOS
- [ ] `і`, `ї`, `є`, `ґ` enter correctly using right Option
- [ ] Layout survives sign-out and reboot
- [ ] Both MacBook and external Windows keyboard tested
- [ ] Switching shortcuts tested without overriding application hotkeys
- [ ] Mac output artifact built from source and checksummed
- [ ] Windows binaries rebuilt from trusted toolchain
- [ ] Linux installer is idempotent, reversible, and does not replace system registry files blindly
