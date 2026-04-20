#!/usr/bin/env bash

set -euo pipefail

poll_interval="${POLL_INTERVAL_SECONDS:-2}"
rnnoise_source_node="${RNNOISE_SOURCE_NODE_NAME:-rnnoise_mic}"
rnnoise_capture_node="${RNNOISE_CAPTURE_NODE_NAME:-capture.rnnoise_mic}"
rnnoise_target_port_override="${RNNOISE_TARGET_PORT:-}"
ignored_source_nodes="${IGNORE_SOURCE_NODE_NAMES:-${rnnoise_source_node},${rnnoise_capture_node}}"

require_commands() {
    local cmd
    for cmd in awk pw-link sleep wpctl; do
        command -v "$cmd" >/dev/null 2>&1 || {
            printf '%s\n' "Missing required command: $cmd" >&2
            exit 1
        }
    done
}

current_default() {
    wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null |
        awk -F '"' '/node\.name = / { print $2; exit }'
}

is_ignored_source() {
    local source="$1"
    local ignored

    IFS=',' read -r -a ignored <<< "$ignored_source_nodes"
    for node in "${ignored[@]}"; do
        [[ "$source" == "$node" ]] && return 0
    done

    return 1
}

source_port() {
    local source="$1"
    local preferred_port

    for preferred_port in capture_MONO capture_FL capture_AUX0 capture_FR; do
        if pw-link -o 2>/dev/null | awk -v port="${source}:${preferred_port}" '$0 == port { found = 1 } END { exit found ? 0 : 1 }'; then
            printf '%s\n' "$preferred_port"
            return 0
        fi
    done

    pw-link -o 2>/dev/null | awk -F ':' -v source="$source" '
        $1 == source && $2 ~ /^capture_/ { print $2; exit }
    '
}

target_port() {
    local candidate

    if [[ -n "$rnnoise_target_port_override" ]]; then
        if pw-link -i 2>/dev/null | awk -v port="$rnnoise_target_port_override" '$0 == port { found = 1 } END { exit found ? 0 : 1 }'; then
            printf '%s\n' "$rnnoise_target_port_override"
            return 0
        fi
        return 1
    fi

    for candidate in \
        "${rnnoise_capture_node}:playback_MONO" \
        "${rnnoise_capture_node}:playback_FL" \
        "${rnnoise_capture_node}:playback_AUX0" \
        "${rnnoise_capture_node}:playback_FR"
    do
        if pw-link -i 2>/dev/null | awk -v port="$candidate" '$0 == port { found = 1 } END { exit found ? 0 : 1 }'; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    pw-link -i 2>/dev/null | awk -v node="$rnnoise_capture_node" '
        $0 ~ ("^" node ":playback_") { print; exit }
        tolower($0) ~ /rnnoise/ && $0 ~ /:playback_/ { print; exit }
    '
}

linked_inputs() {
    local target="$1"

    pw-link -I -l 2>/dev/null | awk -v target="$target" '
        $2 == target { in_target = 1; next }
        in_target && /^ *[0-9]+ +\|<-/ {
            link_id = $1
            source = $3
            print link_id "\t" source
            next
        }
        in_target && $0 !~ /^  / { in_target = 0 }
    '
}

disconnect_all_inputs() {
    local target="$1"

    while IFS=$'\t' read -r link_id source; do
        [[ -n "$link_id" ]] || continue
        pw-link -d "$link_id" >/dev/null 2>&1 || true
    done < <(linked_inputs "$target")
}

current_input_count() {
    local target="$1"
    linked_inputs "$target" | wc -l
}

current_input_source() {
    local target="$1"
    linked_inputs "$target" | awk -F '\t' 'NR == 1 { print $2 }'
}

require_commands

while true; do
    current_target="$(target_port || true)"

    if [[ -z "$current_target" ]]; then
        sleep "$poll_interval"
        continue
    fi

    current_source="$(current_default)"

    if [[ -n "$current_source" ]] && ! is_ignored_source "$current_source"; then
        current_port="$(source_port "$current_source" || true)"

        if [[ -n "$current_port" ]]; then
            current_link="${current_source}:${current_port}"
            existing_count="$(current_input_count "$current_target")"
            existing_source="$(current_input_source "$current_target")"

            if [[ "$existing_count" -ne 1 || "$existing_source" != "$current_link" ]]; then
                disconnect_all_inputs "$current_target"
                pw-link "$current_link" "$current_target" >/dev/null 2>&1 || true
            fi
        else
            disconnect_all_inputs "$current_target"
        fi
    else
        disconnect_all_inputs "$current_target"
    fi

    sleep "$poll_interval"
done
