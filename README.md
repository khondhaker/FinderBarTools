# FinderBarTools

FinderBarTools is a macOS menu bar app for common Finder-focused actions. The current version includes six commands:

- New Text File
- Open Terminal Here
- Open iTerm Here
- Open in VS Code
- Open in Antigravity
- Copy Path

The app is designed as a clean starting point for a larger Finder utility menu, similar to the contextual menu tools you showed, but implemented as your own lightweight macOS app.

## Current Status

The app is working as a regular macOS menu bar app.

- It runs from Xcode
- It builds successfully with `xcodebuild`
- It can be copied into `Applications`
- It shows a custom app icon
- It opens a Settings window
- It supports global keyboard shortcuts
- It supports colorful menu bar icon with preset and custom colors
- It supports enabling or disabling individual menu actions from Settings
- It supports reordering menu actions from Settings
- It validates shortcut conflicts in Settings
- It shows lightweight in-menu progress, success, and error feedback for actions
- It supports Finder selection, Finder windows, and the Desktop as action context

## Project Goals

- Provide a menu bar entry point for common Finder actions
- Keep the first release simple and stable
- Use AppleScript for Finder automation so features are easy to understand and extend
- Keep the codebase small enough to grow into a larger utility app later

## Current Structure

- `project.yml`: XcodeGen project spec
- `FinderBarTools.xcodeproj`: generated Xcode project
- `Sources/FinderBarTools/FinderBarTools.swift`: app entry point
- `Sources/FinderBarTools/AppModel.swift`: app-level state and shortcut access
- `Sources/FinderBarTools/MenuBarContent.swift`: menu bar UI
- `Sources/FinderBarTools/FinderActionService.swift`: action dispatch layer
- `Sources/FinderBarTools/AppleScriptRunner.swift`: AppleScript execution helper
- `Sources/FinderBarTools/HotKeyManager.swift`: native global hotkey registration
- `Sources/FinderBarTools/Shortcut.swift`: shortcut model and display formatting
- `Sources/FinderBarTools/ShortcutStore.swift`: persisted shortcut storage
- `Sources/FinderBarTools/SettingsView.swift`: settings window
- `Resources/`: `Info.plist` and asset catalog

## How It Works

The app uses `MenuBarExtra` from SwiftUI to place a menu in the macOS menu bar. Each menu action delegates to `FinderActionService`, which runs an AppleScript against Finder, Terminal, iTerm, or the clipboard.

This keeps the first version practical:

- Finder context comes from the current Finder selection, the front Finder window, or the Desktop
- File creation uses the same numbered naming rule you requested
- Terminal and iTerm open in the resolved Finder folder context
- VS Code opens the resolved Finder folder context as a workspace
- Antigravity opens the resolved Finder folder context as a workspace
- Copy Path copies the selected file or folder path, falling back to the resolved Finder folder
- iTerm, VS Code, and Antigravity menu items display their real app icons
- The menu bar icon can be tinted with a custom color from Settings
- Global hotkeys are registered with Carbon and saved in `UserDefaults`
- Disabled actions are hidden from the menu and ignored by their global hotkeys
- Menu action order can be changed from Settings and is saved in `UserDefaults`
- Duplicate shortcut assignments are blocked with a visible error message
- The menu shows a spinner while actions are running, then a short success or error status
- Copy Path uses a distinct clipboard-themed confirmation pulse
- The app runs as a menu bar utility without a Dock icon

## Recent Changes

The latest updates added several quality-of-life improvements:

- Added `Open in Antigravity` with its real app icon and a default global shortcut
- Added custom menu ordering from Settings
- Added per-feature toggles in Settings so individual actions can be temporarily hidden
- Fixed silent global shortcut conflicts by rejecting duplicate shortcut assignments in Settings
- Improved shortcut recording so `Escape` cancels cleanly and invalid modifier-less captures exit with feedback
- Fixed shortcut label rendering so the default `Open in VS Code` shortcut shows `V` correctly and custom keys display more reliably
- Fixed preset icon color selection so the chosen preset stays highlighted after relaunch
- Added lightweight menu feedback with running, success, and error states
- Added a clipboard-specific pulse animation for `Copy Path`
- Added support for Finder selection and Desktop fallback, so actions no longer require an open Finder window
- Added Settings credit text: `Copyright 2026 Khondhaker Al Momin`

## Default Shortcuts

- New Text File: `Control + Option + Command + N`
- Open Terminal Here: `Control + Option + Command + T`
- Open iTerm Here: `Control + Option + Command + I`
- Open in VS Code: `Control + Option + Command + V`
- Open in Antigravity: `Control + Option + Command + A`
- Copy Path: `Control + Option + Command + P`

## Expected Permissions

When you first run the app, macOS may ask for permission to control:

- Finder
- Terminal
- iTerm
- Visual Studio Code
- Antigravity
- System Events

That is expected because the app uses AppleScript automation.

## Development History

This project was built incrementally from scratch. These were the major steps:

1. Created an initial Swift starter project and README.
2. Scaffoled the first menu bar app structure around the four Finder actions.
3. Verified the Swift source directly before a full Xcode app workflow was available.
4. Installed full Xcode and switched the active developer directory to the Xcode toolchain.
5. Installed `xcodegen` with Homebrew to generate and maintain a proper Xcode macOS app project.
6. Converted the starter into a real macOS application target.
7. Added `LSUIElement` so the app behaves as a menu bar utility rather than a normal Dock app.
8. Added a Settings window and a native global hotkey system using Carbon.
9. Added an app icon asset catalog and fixed the project configuration so the icon compiles into the app bundle correctly.
10. Fixed the Settings menu item to work with the SwiftUI app lifecycle across the current deployment target.
11. Built and validated the app successfully with `xcodebuild`.
12. Copied the built app into `Applications` and confirmed it works as a regular macOS app.

## Issues Encountered And Fixed

During development, several environment and project issues came up:

- The machine initially had only Command Line Tools active, not full Xcode.
- The original Swift package scaffold was not the best final shape for a menu bar app.
- `swift build` was blocked by a local SwiftPM manifest/toolchain mismatch.
- The Settings menu originally used an unsupported opening path for the SwiftUI `Settings` scene.
- The first icon setup produced the generic placeholder because the asset catalog was not being compiled into the app.

These were all resolved by moving the app to a proper Xcode project, adjusting the SwiftUI settings flow, and fixing the asset-catalog configuration in the XcodeGen spec.

## Prerequisites

- macOS
- Xcode installed
- Xcode Command Line Tools available
- Homebrew
- `xcodegen`

Install `xcodegen` if needed:

```bash
brew install xcodegen
```

## Generate The Project

Generate the Xcode project:

```bash
xcodegen generate
```

Then open:

```bash
open FinderBarTools.xcodeproj
```

## Run In Xcode

1. Open `FinderBarTools.xcodeproj`.
2. Select the `FinderBarTools` scheme.
3. Select `My Mac` as the destination.
4. Press `Command + R`.
5. The app icon should appear in the macOS menu bar.
6. Approve any automation permissions macOS asks for.

## Build From Terminal

Build a Debug version:

```bash
xcodebuild -project FinderBarTools.xcodeproj -scheme FinderBarTools -configuration Debug -derivedDataPath .derived build
```

The built app will be located at:

```bash
.derived/Build/Products/Debug/FinderBarTools.app
```

## Use As A Regular App

To use FinderBarTools outside Xcode:

1. Build the app.
2. Open the generated app bundle.
3. Drag `FinderBarTools.app` into your `Applications` folder.
4. Launch it from `Applications`.
5. On first launch, right-click and choose `Open` if macOS prompts you.

Important note:

- Each new Xcode build creates a fresh app in `.derived`
- If you make code changes later, rebuild and copy the new app into `Applications` again

## Customizing Enabled Features

Open `Settings` and use the `Features` toggles to temporarily show or hide individual actions. Disabled actions are removed from the menu and their global shortcuts do nothing until the action is turned back on.

Use the up and down arrow buttons in the same section to reorder actions. The menu and shortcut list follow that saved order.

The setting is saved automatically, so your feature list stays the same after relaunch.

## Customizing Shortcuts

Open the menu bar app and choose `Settings`.

From there you can assign global shortcuts for:

- New Text File
- Open Terminal Here
- Open iTerm Here
- Open in VS Code
- Open in Antigravity
- Copy Path

Recorded shortcuts are saved automatically.

Additional shortcut behavior:

- Duplicate shortcuts are not allowed
- Press `Escape` while recording to cancel
- Shortcuts must include at least one modifier key

## Customizing the Menu Bar Icon

In Settings, toggle **Colorful Icon** to tint the menu bar icon. Choose from eight preset colors (Blue, Purple, Pink, Red, Orange, Green, Teal, White) or pick a custom color with the color picker. The default is a standard monochrome icon that adapts to your menu bar appearance.

## Action Feedback

When you trigger an action from the menu:

- The selected row shows a small spinner while the action is running
- Successful actions show a brief confirmation state in the row and a short status line below the menu actions
- Errors show an orange warning state
- `Copy Path` uses a clipboard-themed confirmation instead of the generic success icon

## Key Files Worth Editing Later

- `Sources/FinderBarTools/FinderActionService.swift`
  Add or modify Finder automation actions here.
- `Sources/FinderBarTools/MenuBarContent.swift`
  Change the visible menu layout here.
- `Sources/FinderBarTools/SettingsView.swift`
  Expand the settings UI here.
- `Resources/Assets.xcassets`
  Replace or refine the app icon here.
- `project.yml`
  Adjust target settings and regenerate the Xcode project here.

## GitHub Publishing Notes

To publish this project to GitHub:

1. Initialize a git repository if one does not exist.
2. Commit the project files.
3. Create a new GitHub repository.
4. Add the remote.
5. Push the local `main` branch.

If GitHub CLI authentication is invalid on the machine, re-authenticate first:

```bash
gh auth login -h github.com
```

Then create and push the repository:

```bash
gh repo create FinderBarTools --public --source=. --remote=origin --push
```

## Planned Next Steps

- Package the app as a polished macOS utility
- Add even richer Finder selection handling for more file-specific workflows
- Add optional preferences for action feedback timing and style
