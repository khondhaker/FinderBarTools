# FinderBarTools

FinderBarTools is a lightweight macOS menu bar app for common Finder-focused actions. It is built with SwiftUI, XcodeGen, AppleScript automation, and native Carbon global hotkeys.

Current commands:

- New Text File
- Open Terminal Here
- Open iTerm Here
- Open in VS Code
- Open in Antigravity
- Copy Path

## Download

The current public release is `v1.0.0`:

https://github.com/khondhaker/FinderBarTools/releases/tag/v1.0.0

Direct unsigned macOS zip:

https://github.com/khondhaker/FinderBarTools/releases/download/v1.0.0/FinderBarTools-v1.0.0-macos-unsigned.zip

This release is unsigned and not notarized. On first launch, macOS may require right-clicking `FinderBarTools.app` and choosing `Open`.

## Install

1. Download `FinderBarTools-v1.0.0-macos-unsigned.zip`.
2. Unzip it.
3. Move `FinderBarTools.app` to `/Applications`.
4. Right-click `FinderBarTools.app` and choose `Open` on first launch if macOS blocks normal opening.
5. Approve any automation permissions requested by macOS.

## Features

- Creates a numbered `new document.txt` in the current Finder folder.
- Opens the current Finder folder in Terminal.
- Opens the current Finder folder in iTerm.
- Opens the current Finder folder in VS Code.
- Opens the current Finder folder in Antigravity.
- Copies the selected file or folder path; if nothing is selected, copies the front Finder window folder; if no window is open, falls back to Desktop.
- Supports Finder selection, front Finder windows, and Desktop fallback.
- Shows app icons for iTerm, VS Code, and Antigravity when those apps are installed.
- Shows in-menu running, success, and error feedback.
- Runs as a menu bar utility without a Dock icon.

## Settings

Open `Settings` from the menu bar popup.

Available settings:

- Launch at login.
- Toggle individual commands on or off.
- Reorder commands with drag-and-drop or the up/down buttons.
- Record global keyboard shortcuts.
- Enable a colorful menu bar icon and choose a preset or custom color.

Disabled commands are hidden from the menu and their global shortcuts do nothing until the command is re-enabled. Settings are saved automatically in `UserDefaults`.

## Default Shortcuts

- New Text File: `Control + Option + Command + N`
- Open Terminal Here: `Control + Option + Command + T`
- Open iTerm Here: `Control + Option + Command + I`
- Open in VS Code: `Control + Option + Command + V`
- Open in Antigravity: `Control + Option + Command + A`
- Copy Path: `Control + Option + Command + P`

Shortcut rules:

- Duplicate shortcuts are rejected.
- Press `Escape` while recording to cancel.
- Shortcuts must include at least one modifier key.

## Permissions

FinderBarTools uses AppleScript automation. Depending on which commands you use, macOS may ask permission to control:

- Finder
- Terminal
- iTerm
- Visual Studio Code
- Antigravity
- System Events

These prompts are expected.

## Requirements

For users:

- macOS 13 or later

For development:

- macOS
- Full Xcode app installed
- Xcode Command Line Tools
- Homebrew
- XcodeGen

Install XcodeGen if needed:

```bash
brew install xcodegen
```

## Project Structure

- `project.yml`: XcodeGen project spec.
- `FinderBarTools.xcodeproj`: generated Xcode project.
- `Sources/FinderBarTools/FinderBarTools.swift`: app entry point and scenes.
- `Sources/FinderBarTools/AppModel.swift`: app state, feature visibility, ordering, feedback, and settings-window focus.
- `Sources/FinderBarTools/MenuBarContent.swift`: menu bar popup UI.
- `Sources/FinderBarTools/FinderActionService.swift`: Finder action dispatch and AppleScript command scripts.
- `Sources/FinderBarTools/AppleScriptRunner.swift`: AppleScript execution helper.
- `Sources/FinderBarTools/HotKeyManager.swift`: native global hotkey registration.
- `Sources/FinderBarTools/Shortcut.swift`: shortcut model and display formatting.
- `Sources/FinderBarTools/ShortcutStore.swift`: persisted shortcut storage.
- `Sources/FinderBarTools/SettingsView.swift`: settings UI, shortcut recorder, feature toggles, and drag sorting.
- `Sources/FinderBarTools/LaunchAtLoginManager.swift`: launch-at-login support.
- `Resources/Info.plist`: app metadata and menu bar utility configuration.
- `Resources/Assets.xcassets`: app icon assets.

## Generate The Project

Regenerate the Xcode project after changing `project.yml`:

```bash
xcodegen generate
```

Open the project:

```bash
open FinderBarTools.xcodeproj
```

## Build

Debug build:

```bash
xcodebuild -project FinderBarTools.xcodeproj -scheme FinderBarTools -configuration Debug -derivedDataPath .derived build
```

Debug app path:

```bash
.derived/Build/Products/Debug/FinderBarTools.app
```

Release build:

```bash
xcodebuild -project FinderBarTools.xcodeproj -scheme FinderBarTools -configuration Release -derivedDataPath .derived-release build
```

Release app path:

```bash
.derived-release/Build/Products/Release/FinderBarTools.app
```

## Package An Unsigned Release

Build Release first, then package the app as a zip. Replace `v1.0.0` with the version being released:

```bash
VERSION=v1.0.0
mkdir -p dist
ditto -c -k --norsrc --keepParent .derived-release/Build/Products/Release/FinderBarTools.app "dist/FinderBarTools-${VERSION}-macos-unsigned.zip"
```

Create and push a tag:

```bash
git tag -a "$VERSION" -m "FinderBarTools ${VERSION}"
git push origin "$VERSION"
```

Create a GitHub Release and upload the zip:

```bash
gh release create "$VERSION" "dist/FinderBarTools-${VERSION}-macos-unsigned.zip" \
  --title "FinderBarTools ${VERSION}" \
  --notes "Unsigned macOS zip release. Download the zip, unzip it, move FinderBarTools.app to /Applications, then right-click Open on first launch if macOS warns that the app is from an unidentified developer."
```

## Notes

- The public `v1.0.0` release is unsigned and not notarized.
- Full Xcode is required for reliable app bundle builds; Command Line Tools alone are not enough for this project.
- Build artifacts under `.derived`, `.derived-release`, and `dist` are generated locally and should not be committed.
