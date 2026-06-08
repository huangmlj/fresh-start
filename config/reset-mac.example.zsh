# Copy this file to:
#   ~/.config/reset-mac/config.zsh
#
# App names must match the names shown by:
#   ./bin/reset-mac --list

# Apps that should never be closed.
KEEP_APPS+=(
  "Finder"
  "Raycast"
  "1Password"
)

# Bundle identifiers that should never be closed.
# The installed one-click launcher uses this id and is kept by default.
KEEP_BUNDLE_IDS+=(
  "local.reset-mac.one-click"
)

# Some apps ignore normal AppleScript quit. For these, reset-mac sends a
# regular TERM signal after SOFT_TERM_DELAY_SECONDS if they are still running.
SOFT_TERM_BUNDLE_IDS+=(
  "com.tencent.xinWeChat"
)
SOFT_TERM_DELAY_SECONDS=2

# Menu bar/background apps are not touched by default.
# Add only the ones you are comfortable quitting before sleep.
MENU_BAR_APPS+=(
  # "Dropbox"
  # "Google Drive"
)

# Extra process names are only killed when you pass --kill-extra.
EXTRA_PROCESSES+=(
  # "node"
  # "adb"
)

# Seconds to wait after a graceful quit before --force kills remaining apps.
TIMEOUT_SECONDS=12
