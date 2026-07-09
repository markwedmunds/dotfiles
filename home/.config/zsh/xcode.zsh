# Xcode command-line helpers for the Helix / terminal workflow.
#
# Helix has no in-editor build/run/test (unlike xcodebuild.nvim), so these
# mirror those keymaps from the shell: xb = build, xr = build & run, xt = test.
# All build logs pipe through xcbeautify. Choose the target simulator with
# XC_DEST and the scheme with XC_SCHEME (or pass the scheme as the first arg):
#
#   export XC_DEST='platform=iOS Simulator,name=iPhone 17 Pro'
#   export XC_SCHEME=MyApp
#   xboot          # open Simulator.app and boot that device
#   xschemes       # list schemes/targets in the project here
#   xdest MyApp    # list run destinations for a scheme
#   xb             # build
#   xt             # test
#   xr             # build, install on the booted sim, launch

: "${XC_DEST:=platform=iOS Simulator,name=iPhone 17 Pro}"

# Populate $reply with the right -workspace/-project flag for the cwd, favouring
# a workspace (what Xcode opens when both exist). Returned as an array so paths
# with spaces survive. (N) is nullglob: no match -> empty, not an error.
_xc_proj() {
  local ws=(*.xcworkspace(N)) pj=(*.xcodeproj(N))
  if (( $#ws )); then
    reply=(-workspace "$ws[1]")
  elif (( $#pj )); then
    reply=(-project "$pj[1]")
  else
    print -u2 "xc: no .xcworkspace or .xcodeproj in $PWD"
    return 1
  fi
}

# Resolve the scheme from $1 or $XC_SCHEME.
_xc_scheme() {
  local s="${1:-$XC_SCHEME}"
  if [[ -z "$s" ]]; then
    print -u2 "xc: no scheme - pass one or set XC_SCHEME (run xschemes to list)"
    return 1
  fi
  print -r -- "$s"
}

# Pull a single build setting's value out of `xcodebuild -showBuildSettings`
# output (lines look like `    KEY = value`).
_xc_setting() {  # _xc_setting <settings-text> <KEY>
  local line=${${(M)${(f)1}:#*$2 = *}[1]}
  print -r -- "${line##* = }"
}

xschemes() { local -a reply; _xc_proj || return; xcodebuild -list "${reply[@]}"; }

xdest() {
  local -a reply; _xc_proj || return
  local s; s=$(_xc_scheme "$1") || return
  xcodebuild -showdestinations "${reply[@]}" -scheme "$s"
}

# Boot a simulator by name (defaults to the device named in XC_DEST).
xboot() {
  local name="${1:-${XC_DEST##*name=}}"
  open -a Simulator
  xcrun simctl boot "$name" 2>/dev/null
  print -r -- "booted: $name"
}

xb() {
  setopt local_options pipe_fail
  local -a reply; _xc_proj || return
  local s; s=$(_xc_scheme "$1") || return
  xcodebuild "${reply[@]}" -scheme "$s" -destination "$XC_DEST" build | xcbeautify
}

xt() {
  setopt local_options pipe_fail
  local -a reply; _xc_proj || return
  local s; s=$(_xc_scheme "$1") || return
  xcodebuild "${reply[@]}" -scheme "$s" -destination "$XC_DEST" test | xcbeautify
}

# Build, then install the product on the booted simulator and launch it.
# Run `xboot` first if nothing is booted.
xr() {
  setopt local_options pipe_fail
  local -a reply; _xc_proj || return
  local -a proj=("${reply[@]}")
  local s; s=$(_xc_scheme "$1") || return

  xcodebuild "${proj[@]}" -scheme "$s" -destination "$XC_DEST" build | xcbeautify || return

  local settings; settings=$(xcodebuild "${proj[@]}" -scheme "$s" -destination "$XC_DEST" -showBuildSettings 2>/dev/null)
  local dir name bid
  dir=$(_xc_setting "$settings" TARGET_BUILD_DIR)
  name=$(_xc_setting "$settings" FULL_PRODUCT_NAME)
  bid=$(_xc_setting "$settings" PRODUCT_BUNDLE_IDENTIFIER)
  if [[ -z "$dir" || -z "$name" || -z "$bid" ]]; then
    print -u2 "xr: could not resolve product path / bundle id from build settings"
    return 1
  fi

  xcrun simctl install booted "$dir/$name" || return
  xcrun simctl launch booted "$bid"
}
