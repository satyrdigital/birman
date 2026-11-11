# macOS installation (all users)

This fork installs the keyboard layouts using a **native macOS installer package**. There is no Keyboard Installer.app, drag-and-drop step, daemon, key interception, or global keyboard shortcut remapping.

## Build and install

The package is assembled on a macOS runner from the checked-in XML keyboard sources using Apple's tools:

```bash
bash Mac/scripts/build-pkg.sh
```

The unsigned package is written to `dist/Birman-Typographic-Layouts-macOS-2.0.0.pkg`. Alternatively, download the `birman-macos-pkg` artifact from the macOS package GitHub Actions run for this branch. The package is **not signed or notarized**; for personal use it can be built locally and installed with explicit user approval. Inspect the content and checksum before installing.

- Install the `.pkg` with the macOS Installer interface. It copies `UkrainianTypographicLayouts.bundle` to `/Library/Keyboard Layouts/` (available for all local accounts).
- **Log out and sign back in** to refresh input sources.
- Open **System Settings → Keyboard → Text Input → Edit**, add `Russian (Typographic + Ukrainian)` and remove obsolete duplicates.
- Ensure the layout appears as a selectable input source and test Ukrainian letters using the **Option** key.

The installer cannot reliably activate a new input source on behalf of all users: macOS tracks chosen input sources **per user**. Installing it system-wide and enabling it per user are separate steps.

## Shortcuts belong to macOS, not the layout

This package installs **only keyboard layouts**. It does **not** alter shortcut or modifier settings. The shortcut `Command + Space` configured for input-source switching on a MacBook is therefore preserved. If left Alt on an external Windows keyboard is mapped to Command, `Alt + Space` on that keyboard invokes the **same** macOS shortcut. Both must be configured in macOS settings independently of the layout.

If clicking the menu chooses the typographic layout but the shortcut does not:

1. Ensure the typographic layout is in **System Settings → Keyboard → Text Input → Edit**, not just the installed layout folder.
2. Remove the undesired standard Russian input source after verifying the typographic input source works.
3. In **System Settings → Keyboard → Keyboard Shortcuts → Input Sources**, verify the exact shortcut used for the active source-switching action and check for Spotlight conflicts.
4. Test the shortcut in TextEdit with exactly two active input sources; restart the session if the new source does not appear in the switcher.

## Security boundaries

- This is a static keyboard-layout bundle plus a **build-time-only** Swift icon generator.
- The Swift icon generator is never installed or run on users' Macs.
- No runtime processes, background services, keyboard hooks, login items, or scripts are included in the final package.
- The neutral **RU** icon is rendered into the package payload instead of the inherited flag resource.
- The inherited `Mac/dst/UkrainianTypographicLayouts.dmg` is **legacy** and must not be installed to test this version.
- This package has not been validated on the target Apple Silicon Mac until explicitly tested; GitHub CI proves the build only.
