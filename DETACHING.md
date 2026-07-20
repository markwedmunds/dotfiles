# Reducing friction / detaching from Nix

Notes for future-me. Captured 2026-07-20 while weighing how to make ad-hoc tool
installs less painful without losing the setup. **Nothing here is applied yet.**

## What this setup actually is

Despite living in a repo I keep calling "the nixos setup", this is a **macOS
nix-darwin** stack in four independent layers:

| Layer | Tool | Manages |
|---|---|---|
| Nix daemon | Determinate Nix | the `nix` binary + `/nix/store` |
| System | nix-darwin (`configuration.nix`) | macOS defaults, Homebrew |
| User env | home-manager (`home.nix`) | CLI packages + generates `~/.zshrc`/`~/.zshenv` |
| Brew | nix-homebrew | `herdr`, `xcode-build-server`, wezterm, claude-code |

## The key realisation

Most config is **not** trapped in the nix store. nvim, helix, wezterm, the zsh
xcode helpers, and claude settings all use `mkOutOfStoreSymlink` (`home.nix`
lines ~287-307), so `~/.config/nvim` -> `~/.dotfiles/home/.config/nvim`. The real
files live in this repo and are already edited in place. Detaching would not
touch them.

The friction is only three things:

1. **`homebrew.onActivation.cleanup = "zap"`** (`configuration.nix:34`) - deletes
   any brew package not listed in the nix config on every rebuild, so
   `brew install foo` gets wiped. This is ~80% of the ad-hoc-install pain.
2. **`home.packages`** (`home.nix:11-31`) - CLI tools; adding one means edit +
   rebuild.
3. **`~/.zshrc` / `~/.zshenv` generated into the read-only nix store** - this is
   what blocked rustup from writing PATH (worked around in `home.nix:38-43`).

## Options, by effort

### Option A - Fix the friction, keep Nix (~15 min, near-zero risk) [RECOMMENDED]

One line in `configuration.nix`. Lets ad-hoc `brew install`s survive rebuilds.

```diff
--- a/configuration.nix
+++ b/configuration.nix
@@ homebrew = {
     enable = true;
-    onActivation.cleanup = "zap";  # remove anything not listed here
+    onActivation.cleanup = "none";  # leave ad-hoc `brew install`s alone
     onActivation.autoUpdate = true;
     onActivation.extraFlags = [ "--force" ];
```

`cleanup` values:

| Value | Behaviour on rebuild |
|---|---|
| `"zap"` (current) | Uninstalls **and** deletes files for any brew pkg not listed |
| `"uninstall"` | Uninstalls unlisted pkgs, keeps their data |
| `"none"` (proposed) | Touches nothing - hand-installed brews survive |

Trade-off: with `"none"`, hand-installed brews become invisible to the config, so
a fresh-machine `bootstrap.sh` won't reinstall them. Still add things to
`brews`/`casks` if you want them reproduced - `"none"` just stops *forcing* it.
Takes effect on next `./rebuild.sh`.

### Option B - Detach the shell only (~1 hour)

Stop home-manager generating the zsh files; move the config to a plain
`~/.dotfiles/home/.zshrc` symlinked manually (or via `mkOutOfStoreSymlink`). Then
`.zshenv`/PATH are writable and tools like rustup "just work". Keep everything
else declarative. Removes the read-only-shell class of problem permanently.

### Option C - Full detach, remove Nix entirely (~half a day, reversible until the last step)

- Reinstall every `home.packages` tool via Homebrew (all are in brew: ripgrep,
  fd, fzf, jq, lazygit, neovim, helix, tree-sitter, node, the LSPs, fvm, the Hack
  nerd font).
- Hand-write `~/.zshrc`/`~/.zshenv`, reconstructed from the currently-generated
  files (starship init, aliases, LS_COLORS, xcode source are all recoverable).
- Replace the `mkOutOfStoreSymlink`s with a plain `ln -s` script or GNU stow -
  same symlinks, made by a shell script instead of home-manager.
- Uninstall home-manager, then nix-darwin, then Determinate Nix (`/nix/uninstall`).
- macOS defaults already persisted, so they stay; optionally capture them in a
  `defaults write` script.

Nothing is lost in any option - this repo is the source of truth and the config
files already live here. Full detach is reversible until the Nix uninstaller runs
(the last step).

## Recommendation

Do **Option A** when the ad-hoc-install pain resurfaces (kills it in one line),
and add **Option B** if the read-only shell keeps annoying. Option C trades a
reproducible one-command-rebuild setup for manual `brew install`s to solve what
is essentially two config lines plus the shell generation - more work and risk
than the problem warrants.
