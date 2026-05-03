#!/usr/bin/env bash
set -euo pipefail

cache_file="${TMUX_BATTERY_TIME_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/tmux/battery-time}"

[[ -r "$cache_file" ]] || exit 0
cat "$cache_file"
