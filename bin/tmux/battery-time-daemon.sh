#!/usr/bin/env bash
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux"
cache_file="${TMUX_BATTERY_TIME_CACHE:-$cache_dir/battery-time}"
state_file="$cache_dir/battery-time-state"
interval="${TMUX_BATTERY_TIME_INTERVAL:-300}"
min_elapsed="${TMUX_BATTERY_TIME_MIN_ELAPSED:-240}"

read_battery() {
	local battery_dir=""
	local dir status energy_now power_now

	for dir in /sys/class/power_supply/*; do
		[[ -d "$dir" ]] || continue
		[[ "$(cat "$dir/type" 2>/dev/null || true)" == "Battery" ]] || continue
		battery_dir="$dir"
		break
	done

	[[ -n "$battery_dir" ]] || return 1

	status="$(cat "$battery_dir/status" 2>/dev/null || true)"

	energy_now=""
	power_now=""

	if [[ -r "$battery_dir/energy_now" ]]; then
		energy_now="$(cat "$battery_dir/energy_now")"
	elif [[ -r "$battery_dir/charge_now" && -r "$battery_dir/voltage_now" ]]; then
		energy_now="$(awk -v c="$(cat "$battery_dir/charge_now")" -v v="$(cat "$battery_dir/voltage_now")" 'BEGIN { printf "%.0f", (c * v) / 1000000 }')"
	fi

	if [[ -r "$battery_dir/power_now" ]]; then
		power_now="$(cat "$battery_dir/power_now")"
	elif [[ -r "$battery_dir/current_now" && -r "$battery_dir/voltage_now" ]]; then
		power_now="$(awk -v c="$(cat "$battery_dir/current_now")" -v v="$(cat "$battery_dir/voltage_now")" 'BEGIN { printf "%.0f", (c * v) / 1000000 }')"
	fi

	[[ "$energy_now" =~ ^[0-9]+$ ]] || return 1
	printf '%s %s %s\n' "$status" "$energy_now" "${power_now:-0}"
}

format_remaining() {
	awk -v energy="$1" -v power="$2" 'BEGIN {
  if (power <= 0) exit
  minutes = int((energy / power) * 60 + 0.5)
  hours = int(minutes / 60)
  mins = minutes % 60
  if (hours > 0) {
    printf " %dh%02dm", hours, mins
  } else {
    printf " %dm", mins
  }
}'
}

estimate() {
	local now status energy_now power_now prev_time prev_energy elapsed energy_drop avg_power

	now="$(date +%s)"
	read -r status energy_now power_now < <(read_battery) || return 0

	if [[ "$status" != "Discharging" ]]; then
		printf '%s %s\n' "$now" "$energy_now" >"$state_file"
		return 0
	fi

	if [[ -r "$state_file" ]]; then
		read -r prev_time prev_energy <"$state_file" || true
		if [[ "${prev_time:-}" =~ ^[0-9]+$ && "${prev_energy:-}" =~ ^[0-9]+$ ]]; then
			elapsed=$((now - prev_time))
			energy_drop=$((prev_energy - energy_now))
			if ((elapsed >= min_elapsed && energy_drop > 0)); then
				avg_power=$((energy_drop * 3600 / elapsed))
				printf '%s %s\n' "$now" "$energy_now" >"$state_file"
				format_remaining "$energy_now" "$avg_power"
				return 0
			fi
		fi
	fi

	printf '%s %s\n' "$now" "$energy_now" >"$state_file"
	if [[ "$power_now" =~ ^[0-9]+$ && "$power_now" -gt 0 ]]; then
		format_remaining "$energy_now" "$power_now"
	fi
}

write_cache() {
	local tmp output

	mkdir -p "$cache_dir"
	output="$(estimate)"
	tmp="$(mktemp "$cache_dir/.battery-time.XXXXXX")"
	printf '%s' "$output" >"$tmp"
	mv "$tmp" "$cache_file"
}

while true; do
	write_cache
	sleep "$interval"
done
