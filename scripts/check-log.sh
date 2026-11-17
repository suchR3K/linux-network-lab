#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

usage() {
    printf 'Usage: bash %s [-p literal_pattern] -- log_file\n' "$0"
}

pattern=ERROR
while getopts ':p:h' option; do
    case "$option" in
        p) pattern=$OPTARG ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
shift "$((OPTIND - 1))"
if (( $# != 1 )) || [[ -z $pattern || $pattern == *$'\n'* ]]; then
    usage >&2
    exit 2
fi
log_file=$1
if [[ ! -f $log_file || ! -r $log_file ]]; then
    printf 'ERROR: log is not a readable regular file: %s\n' "$log_file" >&2
    exit 2
fi

# grep counts matching lines, not occurrences. A no-match exit is expected.
if count=$(grep -a -i -F -c -- "$pattern" "$log_file"); then
    printf 'WARN: %s matching lines in %s\n' "$count" "$log_file"
    exit 1
else
    grep_status=$?
    if (( grep_status == 1 )); then
        printf 'OK: no matching lines in %s\n' "$log_file"
        exit 0
    fi
    printf 'ERROR: could not scan log: %s\n' "$log_file" >&2
    exit 2
fi
