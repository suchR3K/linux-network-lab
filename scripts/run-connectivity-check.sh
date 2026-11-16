#!/usr/bin/env bash

set -u

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(dirname -- "$script_dir")"
log_dir="$project_dir/logs"

mkdir -p "$log_dir" || exit 1

log_file="$log_dir/connectivity.log"

{
   printf '\n=== %s ===\n' "$(date --iso-8601=seconds)"
   "$script_dir/check-connectivity.sh"
   result=$?
   printf 'Kod zakonczenia: %s\n' "$result"
} >> "$log_file" 2>&1

printf 'Wynik zapisano w %s\n' "$log_file"
exit "$result"
