#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

usage() {
    printf 'Usage: bash %s [-t threshold_MiB] -d directory [-d directory ...]\n' "$0"
}

threshold=500
directories=()
while getopts ':t:d:h' option; do
    case "$option" in
        t) threshold=$OPTARG ;;
        d) directories+=("$OPTARG") ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
shift "$((OPTIND - 1))"
if (( $# != 0 || ${#directories[@]} == 0 )) ||
   [[ ! $threshold =~ ^[0-9]{1,9}$ ]]; then
    usage >&2
    exit 2
fi
threshold=$((10#$threshold))
result=0
for directory in "${directories[@]}"; do
    if [[ ! -d $directory ]]; then
        printf 'ERROR: not a directory: %s\n' "$directory" >&2
        result=2
        continue
    fi
    if measurement=$(du -sm -- "$directory"); then
        size=${measurement%%[[:space:]]*}
        if (( size >= threshold )); then
            printf 'WARN: %s uses %s MiB (threshold: %s MiB)\n' "$directory" "$size" "$threshold"
            if (( result == 0 )); then result=1; fi
        else
            printf 'OK: %s uses %s MiB\n' "$directory" "$size"
        fi
    else
        printf 'ERROR: could not measure: %s\n' "$directory" >&2
        result=2
    fi
done
exit "$result"
