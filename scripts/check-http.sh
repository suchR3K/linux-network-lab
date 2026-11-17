#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

usage() {
    printf 'Usage: bash %s [-e expected_status] [-t timeout_seconds] -- URL\n' "$0"
}

expected=200
timeout=10
while getopts ':e:t:h' option; do
    case "$option" in
        e) expected=$OPTARG ;;
        t) timeout=$OPTARG ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
shift "$((OPTIND - 1))"
if (( $# != 1 )) || [[ ! $expected =~ ^[1-5][0-9]{2}$ ]] ||
   [[ ! $timeout =~ ^[1-9][0-9]{0,2}$ ]]; then
    usage >&2
    exit 2
fi
url=$1
case "$url" in
    http://*|https://*) ;;
    *) printf 'ERROR: URL must use HTTP or HTTPS.\n' >&2; exit 2 ;;
esac
if ! command -v curl >/dev/null 2>&1; then
    printf 'ERROR: curl is required.\n' >&2
    exit 2
fi

# No redirects, retries, TLS bypass or response-body logging.
# --disable ignores per-user curl configuration; --globoff treats the URL literally.
if actual=$(curl --disable --silent --show-error --globoff \
    --proto '=http,https' --connect-timeout "$timeout" \
    --max-time "$timeout" --output /dev/null \
    --write-out '%{http_code}' --url "$url"); then
    if [[ $actual == "$expected" ]]; then
        printf 'OK: HTTP %s\n' "$actual"
        exit 0
    fi
    printf 'FAIL: expected HTTP %s, received %s\n' "$expected" "$actual"
else
    printf 'FAIL: HTTP request did not complete.\n' >&2
fi
exit 1
