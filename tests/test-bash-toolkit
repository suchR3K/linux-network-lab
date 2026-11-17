#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT

check() {
    local expected=$1
    shift
    local actual=0
    "$@" > "$temporary/output" 2>&1 || actual=$?
    if (( actual != expected )); then
        cat "$temporary/output"
        printf 'FAIL: expected exit %s, received %s\n' "$expected" "$actual" >&2
        exit 1
    fi
    printf 'PASS: %s (exit %s)\n' "$*" "$actual"
}

mkdir -p "$temporary/with spaces"
check 0 bash "$root/scripts/check-directory-size.sh" -t 500 -d "$temporary/with spaces"
check 1 bash "$root/scripts/check-directory-size.sh" -t 0 -d "$temporary/with spaces"
check 2 bash "$root/scripts/check-directory-size.sh" -t invalid -d "$temporary"
check 2 bash "$root/scripts/check-directory-size.sh" -t 0 -d "$temporary/missing" -d "$temporary"

printf 'INFO started\nerror connection failed\nERROR ERROR\n' > "$temporary/example.log"
check 1 bash "$root/scripts/check-log.sh" -- "$temporary/example.log"
grep -q '2 matching lines' "$temporary/output"
check 0 bash "$root/scripts/check-log.sh" -p '[fatal]' -- "$temporary/example.log"
check 2 bash "$root/scripts/check-log.sh" -- "$temporary/missing.log"
check 2 bash "$root/scripts/check-log.sh" -p '' -- "$temporary/example.log"
check 2 bash "$root/scripts/check-http.sh" -- file:///etc/passwd
check 2 bash "$root/scripts/check-http.sh" -t 0 -- http://127.0.0.1

# A controlled curl stub tests script decisions without contacting a server.
# This is not a live HTTP integration test.
mkdir "$temporary/bin"
cat > "$temporary/bin/curl" <<'STUB'
#!/usr/bin/env bash
printf '%s' "${MOCK_HTTP_CODE:-200}"
exit "${MOCK_CURL_EXIT:-0}"
STUB
chmod +x "$temporary/bin/curl"
check 0 env PATH="$temporary/bin:$PATH" MOCK_HTTP_CODE=200 MOCK_CURL_EXIT=0 bash "$root/scripts/check-http.sh" -- http://example.test
check 1 env PATH="$temporary/bin:$PATH" MOCK_HTTP_CODE=503 MOCK_CURL_EXIT=0 bash "$root/scripts/check-http.sh" -- http://example.test
check 0 env PATH="$temporary/bin:$PATH" MOCK_HTTP_CODE=204 MOCK_CURL_EXIT=0 bash "$root/scripts/check-http.sh" -e 204 -- http://example.test
check 1 env PATH="$temporary/bin:$PATH" MOCK_HTTP_CODE=000 MOCK_CURL_EXIT=28 bash "$root/scripts/check-http.sh" -- http://example.test

printf 'All 14 cases passed.\n'
