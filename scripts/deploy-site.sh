#!/usr/bin/env bash
set -euo pipefail

# Run from a Linux machine with SSH access to lab-server.
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
options=()
case "${1:-}" in
    --dry-run) options+=(--dry-run); shift ;;
    -h|--help) printf 'Usage: bash %s [--dry-run]\n' "$0"; exit 0 ;;
    '') ;;
    *) printf 'Unknown option. Use --help.\n' >&2; exit 2 ;;
esac
if (( $# != 0 )); then
    printf 'Unexpected arguments.\n' >&2
    exit 2
fi
for tool in rsync ssh; do
    command -v "$tool" >/dev/null || { printf 'Missing tool: %s\n' "$tool" >&2; exit 2; }
done
for asset in index.html styles.css; do
    [[ -s "$root/site/$asset" ]] || { printf 'Missing asset: %s\n' "$asset" >&2; exit 2; }
done

# Explicit asset list: never transfer the repository, credentials or logs.
# No remote deletion. Fixed destination matches the documented lab setup.
rsync --times --perms --checksum --itemize-changes --chmod=F644 \
    -e 'ssh -o ConnectTimeout=10' "${options[@]}" -- \
    "$root/site/index.html" "$root/site/styles.css" \
    julia@192.168.50.1:/var/www/lab-portal/
if (( ${#options[@]} > 0 )); then
    printf 'Dry run complete. No files transferred.\n'
else
    printf 'Transfer complete. Verify HTTP separately from lab-client.\n'
fi
