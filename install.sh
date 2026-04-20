#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pipewire_dir="${HOME}/.config/pipewire/pipewire.conf.d"
bin_dir="${HOME}/.local/bin"
systemd_dir="${HOME}/.config/systemd/user"
pipewire_config="${pipewire_dir}/99-rnnoise-source.conf"

find_rnnoise_plugin() {
    local candidate

    if [[ -n "${RNNOISE_PLUGIN_PATH:-}" ]]; then
        if [[ -f "${RNNOISE_PLUGIN_PATH}" ]]; then
            printf '%s\n' "${RNNOISE_PLUGIN_PATH}"
            return 0
        fi

        printf '%s\n' "RNNOISE_PLUGIN_PATH is set but file does not exist: ${RNNOISE_PLUGIN_PATH}" >&2
        return 1
    fi

    for candidate in \
        /usr/lib/ladspa/librnnoise_ladspa.so \
        /usr/lib64/ladspa/librnnoise_ladspa.so \
        /usr/local/lib/ladspa/librnnoise_ladspa.so \
        /usr/local/lib64/ladspa/librnnoise_ladspa.so
    do
        [[ -f "$candidate" ]] && {
            printf '%s\n' "$candidate"
            return 0
        }
    done

    find /usr/lib /usr/lib64 /usr/local/lib /usr/local/lib64 \
        -path '*/ladspa/librnnoise_ladspa.so' -print -quit 2>/dev/null
}

mkdir -p "$pipewire_dir" "$bin_dir" "$systemd_dir"

plugin_path="$(find_rnnoise_plugin || true)"

if [[ -z "$plugin_path" ]]; then
    printf '%s\n' "Could not find librnnoise_ladspa.so. Install the RNNoise LADSPA package or rerun with RNNOISE_PLUGIN_PATH=/full/path/to/librnnoise_ladspa.so." >&2
    exit 1
fi

sed "s|@RNNOISE_PLUGIN_PATH@|${plugin_path}|g" "${repo_dir}/99-rnnoise-source.conf" > "$pipewire_config"
install -m 0755 "${repo_dir}/rnnoise-watch-default.sh" "${bin_dir}/rnnoise-watch-default.sh"
install -m 0644 "${repo_dir}/rnnoise-watch-default.service" "${systemd_dir}/rnnoise-watch-default.service"

systemctl --user daemon-reload
systemctl --user enable --now rnnoise-watch-default.service
systemctl --user restart pipewire pipewire-pulse wireplumber

printf '%s\n' "Installed RNNoise Mic watcher."
printf '%s\n' "Using RNNoise plugin at ${plugin_path}."
