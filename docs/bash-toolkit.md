# Bash Operations Toolkit

Three small scripts extending the Linux Network Lab. They do not install services, change networking, restart processes or remove user data.

## Requirements

Target: Ubuntu/Linux, Bash 4+, GNU coreutils (`du`), GNU grep, and curl for HTTP checks. Run with `bash`; executable file permissions are optional.

## Scripts

| Script | Purpose | Bash concepts |
|---|---|---|
| `scripts/check-directory-size.sh` | Report allocated directory space and flag a configurable threshold | getopts, arrays, loops, arithmetic, functions |
| `scripts/check-log.sh` | Count lines containing a literal, case-insensitive pattern | grep, command substitution, input validation, exit codes |
| `scripts/check-http.sh` | Check the HTTP status of a GET request with timeouts | curl, case, options, conditionals |

### Directory sizes

```bash
bash scripts/check-directory-size.sh -t 500 -d "$HOME/projects" -d "$HOME/Downloads"
```

Thresholds are in MiB, using GNU `du -sm` (allocated space rounded upward). A directory at or above the threshold produces a warning. Multiple directories are independent measurements, not a combined total. This does not measure free filesystem space. Unreadable content is an error, not a successful partial measurement.

### Log scanning

```bash
bash scripts/check-log.sh -p ERROR -- /path/to/application.log
```

Counts matching lines, not individual occurrences. Matching is literal and case-insensitive. Empty and multiline patterns are rejected. No matches is a successful result. The script does not print log contents, monitor future entries or interpret log severity structurally. Compressed logs must be decompressed separately.

### HTTP checks

```bash
bash scripts/check-http.sh -e 200 -t 10 -- http://127.0.0.1:8000/ready
```

The example requires Flight API to be reachable on the machine running the script. On lab-server, localhost does not refer to the separate Flight API VM.

The script sends one GET request, discards the response body, verifies TLS normally, and does not follow redirects. It verifies the status code only, not JSON content or complete application health. A 301 response fails when 200 is expected. Timeout values are integers from 1 to 999 seconds. Use trusted, read-only endpoints and avoid embedding credentials in command arguments.

## Exit codes

- `0`: successful check, no warning.
- `1`: threshold reached, matching log lines found, unexpected HTTP status or request failure.
- `2`: invalid arguments, unavailable required tool or local input/read error handled by the script.

Unexpected failures from underlying commands can return their own nonzero exit codes. Use `bash SCRIPT -h` for help.

## Validation

Validation status at delivery: execution in the local Windows sandbox was blocked before Bash could start. The test suite and CI workflow are provided, but a passing run has not yet been confirmed. Check the GitHub Actions result after upload.

```bash
bash tests/test-bash-toolkit.sh
```

The test suite covers 14 cases: thresholds, paths with spaces, invalid input, error precedence, missing files, log line counts, literal patterns and HTTP outcomes. HTTP tests replace curl with a controlled stub; they are not live HTTP integration tests. Test fixtures are created in a temporary directory and removed on exit.

The GitHub Actions workflow runs Bash syntax checks, ShellCheck and these tests on Ubuntu. It checks only the new toolkit files, without assuming that existing lab scripts are already lint-clean.

No Nginx deployment, SSH setup or systemd installation is performed by this toolkit. Deployment to the lab VMs and verification against real services are separate tasks.

## Upload into an existing repository

Copy `scripts/`, `tests/`, `docs/` and `.github/` contents into the matching repository directories. Keep the existing root README and existing scripts. Do not upload the ZIP as a replacement for the individual files. The workflow must be at `.github/workflows/bash-toolkit.yml` in the repository root.

The files use English messages and comments. They were designed from the author's Bash study topics: functions, options, arrays, loops, pipelines, grep, curl, validation and exit codes.
