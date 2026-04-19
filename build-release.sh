#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_name="rnnoise-autoswitch-defaultmic"
dist_dir="${repo_dir}/dist"
staging_dir="$(mktemp -d)"

cleanup() {
    rm -rf "$staging_dir"
}

trap cleanup EXIT

if [[ $# -gt 1 ]]; then
    printf '%s\n' "Usage: ./build-release.sh [version]" >&2
    exit 1
fi

if [[ $# -eq 1 ]]; then
    version="$1"
elif git -C "$repo_dir" describe --tags --exact-match >/dev/null 2>&1; then
    version="$(git -C "$repo_dir" describe --tags --exact-match)"
else
    version="$(date +%Y%m%d)"
fi

archive_root="${project_name}-${version}"
package_dir="${staging_dir}/${archive_root}"

mkdir -p "$package_dir" "$dist_dir"

install -m 0644 "${repo_dir}/99-rnnoise-source.conf" "${package_dir}/99-rnnoise-source.conf"
install -m 0644 "${repo_dir}/rnnoise-watch-default.service" "${package_dir}/rnnoise-watch-default.service"
install -m 0755 "${repo_dir}/rnnoise-watch-default.sh" "${package_dir}/rnnoise-watch-default.sh"
install -m 0755 "${repo_dir}/install.sh" "${package_dir}/install.sh"
install -m 0755 "${repo_dir}/uninstall.sh" "${package_dir}/uninstall.sh"
install -m 0644 "${repo_dir}/README.md" "${package_dir}/README.md"
install -m 0644 "${repo_dir}/LICENSE" "${package_dir}/LICENSE"

archive_path="${dist_dir}/${archive_root}.tar.gz"
tar -C "$staging_dir" -czf "$archive_path" "$archive_root"

printf '%s\n' "Created ${archive_path}"
