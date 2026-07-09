# dotfiles

Watch the walkthrough: https://youtu.be/5N-okeDdIuI

My personal Mac setup, managed with nix-darwin and home-manager.
One repo, one command, and a fresh Mac ends up configured the same way every time.

## Contributing / Using This Repo

These are my personal dotfiles, shared publicly so people can read them, learn from them, and fork them freely.
Feature requests and pull requests are not accepted here, and PRs are auto-closed.
If you find a bug, please open a GitHub Issue using the bug report template.

## What you get

Running the switch builds:

- System settings (dark mode, key repeat, dock, Finder, trackpad)
- Homebrew apps (casks and CLI tools)
- Nix user packages (ripgrep, fd, fzf, jq, lazygit, Neovim, Hack Nerd Font)
- Shell (zsh, aliases, starship prompt, Xcode build/run/test helpers)
- Editors (Neovim and Helix configs)
- Terminal (WezTerm config)
- Agent configs (Claude, Codex, opencode all share one AGENTS.md)

## Prerequisites

- Apple Silicon Mac, by default.
- Intel Mac: change one line.
  In `configuration.nix`, set `nixpkgs.hostPlatform = "x86_64-darwin";` (the comment right there tells you the same thing).

## Fresh-machine setup

On a brand new Mac, from a bare clone of this repo:

```sh
git clone https://github.com/kunchenguid/dotfiles.git
cd dotfiles
```

Before you run it: review "Make it yours" below.
Change the host label or CPU architecture if needed, and read the Homebrew cleanup warning.
`bootstrap.sh` applies the config to your machine, so do this first.

```sh
./bootstrap.sh
```

`bootstrap.sh` does four things, in order:

1. Installs Determinate Nix, if it isn't already installed.
2. Symlinks this repo to `~/.dotfiles`.
   This has to happen before the first build, because `home.nix` points at config files through `~/.dotfiles`.
3. Checks the `user` configured in `flake.nix` against your actual macOS username, and offers to fix it for you if they differ.
4. Runs the first `darwin-rebuild switch`.
   It fetches the `darwin-rebuild` tool from the nix-darwin 26.05 release branch, then applies this repo's locked flake config.

After that, `darwin-rebuild` exists and you're on the normal workflow below.

### Validate without applying

Once Nix is installed (`bootstrap.sh` step 1 handles that), you can check that the config builds without touching your system - handy when you have edited something:

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```

If you renamed the host label in "Make it yours", substitute your label for `mac` in these commands.

## Daily use

Edit the config files in place, then apply:

```sh
./rebuild.sh
```

That's it.
No separate build-and-copy step.

## Swift & iOS development

Two editors are set up for Swift. Neovim uses [xcodebuild.nvim](https://github.com/wojciech-kulik/xcodebuild.nvim) for an in-editor build/run/test picker (`<leader>x…`). Helix has no such plugin, so it handles editing (LSP, formatting, debugging) and the build/run/test loop lives in the shell helpers below.

### Editor setup (both share the same tools)

`sourcekit-lsp`, `swift-format` and `lldb-dap` all ship inside Xcode and are driven through `xcrun`, so there is nothing extra to install:

- **Neovim** - config in `home/.config/nvim/lua/lsp.lua` (LSP) and `plugins/swift.lua` (xcodebuild.nvim).
- **Helix** - config in `home/.config/helix/languages.toml`: sourcekit-lsp for completion/hover, `swift-format` as the formatter (`:format`), and `lldb-dap` for debugging macOS/SwiftPM binaries (`:debug-start binary <path>`). Check it with `hx --health swift`.

### One-time per-project setup (Xcode projects only)

For a `.xcodeproj` / `.xcworkspace` (anything that isn't a plain SwiftPM package), sourcekit-lsp needs a `buildServer.json` so it can resolve modules and dependencies. Run this once in the project root - it's provided by the `xcode-build-server` Homebrew formula:

```sh
xcode-build-server config -scheme <YourScheme> -workspace YourApp.xcworkspace
#            ... or:       -scheme <YourScheme> -project   YourApp.xcodeproj
```

That writes `buildServer.json` at the repo root; reopen the file in your editor and the LSP picks it up. Plain SwiftPM packages (with a `Package.swift`) need no setup.

### Shell build/run/test helpers

Defined in `home/.config/zsh/xcode.zsh`. They auto-detect the `.xcworkspace`/`.xcodeproj` in the current directory (favouring the workspace) and pipe build logs through `xcbeautify`. Pick the target with two env vars - the scheme can also be passed as the first argument:

```sh
export XC_DEST='platform=iOS Simulator,name=iPhone 17 Pro'   # default if unset
export XC_SCHEME=MyApp                                        # or: xb MyApp
```

| Command | What it does |
|---|---|
| `xboot [name]` | Open Simulator.app and boot the device (defaults to the one in `XC_DEST`) |
| `xschemes` | List schemes/targets in the project here |
| `xdest <scheme>` | List run destinations for a scheme |
| `xb [scheme]` | Build |
| `xt [scheme]` | Test |
| `xr [scheme]` | Build, install on the booted sim, then launch |

Debugging an app running on the iOS Simulator is still best done from Xcode itself; `lldb-dap` in Helix covers macOS/SwiftPM executables.

## Flutter & Dart development

Flutter SDKs are managed with [fvm](https://fvm.app) (`fvm` is a nix package; `home.nix` puts `~/fvm/default/bin` on `PATH`). The Flutter CLI is already ergonomic, so unlike Xcode there are no wrapper scripts - just `fvm flutter …`, shortened to the `fl` alias.

### Editor setup

The Dart analysis server, formatter, and debugger all ship with the SDK and are driven through `fvm`, so they honour a project's pinned version (`.fvmrc` / `.fvm/`) and fall back to the global `fvm global` SDK elsewhere. Nothing extra to install:

- **Helix** - config in `home/.config/helix/languages.toml`: `fvm dart language-server` for completion/hover, `fvm dart format` as the formatter (runs on save; flip `auto-format` off to opt out), and the Flutter DAP (`fvm flutter debug_adapter`) for debugging (`:debug-start flutter`, then pick the entrypoint). Check it with `hx --health dart`.
- **Neovim** - Dart LSP works via the built-in defaults; there's no dedicated Flutter plugin config.

No per-project setup step is needed (the analyzer reads `pubspec.yaml` / `.dart_tool` directly) - just make sure you've run `fvm use <version>` and `fvm flutter pub get` in the project.

### Common commands

`fl` is aliased to `fvm flutter`:

| Command | What it does |
|---|---|
| `fvm use <version>` | Pin this project to a Flutter version (writes `.fvmrc`) |
| `fl pub get` | Fetch dependencies |
| `fl devices` | List run targets (simulators, macOS, Chrome, …) |
| `fl run` | Build & run with hot reload (`r` reload, `R` restart, `q` quit) |
| `fl run -d <id>` | Run on a specific device from `fl devices` |
| `fl test` | Run tests |
| `fvm dart format .` | Format the whole tree from the CLI |

Boot an iOS simulator first with the `xboot` helper from the Swift section (`xboot` defaults to the iPhone 17 Pro), then `fl run -d "iPhone 17 Pro"`.

## Make it yours

This repo is mine.
If you clone it, review these before you run `bootstrap.sh`:

- **Username**: run `./bootstrap.sh` (it detects your macOS username and offers to set it) OR change the single `user = "kunchen"` line in `flake.nix`.
  Everything else (`configuration.nix`, `home.nix`, home directory paths) is threaded from that one variable.
- **Host label** `"mac"`, in three places: `flake.nix` (the `darwinConfigurations."mac"` name), `rebuild.sh:5` (the `#mac` at the end of the flake reference), and `bootstrap.sh`'s first-switch command (also `#mac`).
  All three have to match.
- **CPU architecture**, `hostPlatform` in `configuration.nix` (see Prerequisites above).

**Git identity:** this config deliberately does not set your git name or email.
Git will stop your first commit and tell you to set them (`git config --global user.name "Your Name"` and `git config --global user.email you@example.com`).
If you'd rather manage that declaratively, add this back to `home.nix` with your own identity:

```nix
programs.git = {
  enable = true;
  settings.user = {
    name = "Your Name";
    email = "you@example.com";
  };
};
```

**Homebrew cleanup warning:** `configuration.nix` sets `homebrew.onActivation.cleanup = "zap"`.
That means every time you switch, Homebrew removes any package or cask on your machine that isn't listed in the `brews` and `casks` arrays in `configuration.nix`.
If you already have Homebrew stuff installed that isn't in that list, the first switch will uninstall it.
Read through `brews` and `casks` before you run `bootstrap.sh` or `rebuild.sh` for the first time, and add anything you want to keep.

**About `herdr`:** it's in the `brews` list.
It's a real public Homebrew formula (`brew info herdr` finds it in homebrew-core, no tap needed), so it will install fine.
If you don't use it, just remove it from `brews` in your copy.

**Heads-up:**

- `home/AGENTS.md` is my personal agent policy, and `home.nix` installs it for Claude, Codex, and opencode.
  If you clone this repo, you'd silently inherit my agent instructions - edit or delete `home/AGENTS.md` if you don't want that.
- The `cc` and `co` shell aliases in `home.nix` are high-agency shortcuts: `claude --dangerously-skip-permissions` and `codex --full-auto`.
  They're convenient for me, but know what they do before you use them.

## Repo tour

- `flake.nix` - the entry point.
  Wires up nixpkgs, nix-darwin, home-manager, and nix-homebrew, and declares the `mac` machine.
- `configuration.nix` - system-level config: macOS defaults, Homebrew.
- `home.nix` - user-level config: shell, packages, prompt, and the symlinks described below.
- `rebuild.sh` - re-applies the config after the first switch.
  Run this every time you make a change.
- `home/` - the actual config files that get symlinked into place (Neovim, Helix, WezTerm, herdr, Claude settings, the shared `AGENTS.md`, and the Xcode shell helpers in `home/.config/zsh/xcode.zsh`).

## How the symlinks work

The files under `home/` are the real files - editing them here is editing your live config, no rebuild needed to see the change in your editor.
`home.nix` uses `mkOutOfStoreSymlink` to point paths like `~/.config/nvim` straight at `home/.config/nvim` in this repo, so the two never drift out of sync.
You only run `./rebuild.sh` when you change something that isn't just a symlinked file, like a package list or a system default.

## Notes

The first time you launch `nvim`, it bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) by cloning plugins from GitHub.
That needs network access once; after that it's offline.

## License

This repo is licensed under MIT No Attribution.
See `LICENSE`.
