#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C

section() {
    printf '\n=== %s ===\n' "$1"
}

cpu_snapshot() {
    awk '
        /^cpu / {
            total = 0
            for (i = 2; i <= 9; i++) {
                total += $i
            }
            printf "%.0f %.0f\n", total, $5
            exit
        }
    ' /proc/stat
}

section "SERVER REPORT"

printf 'Timestamp: %s\n' "$(date --iso-8601=seconds)"
printf 'Hostname: %s\n' "$(hostname)"
printf 'Kernel: %s\n' "$(uname -r)"

if [[ -r /etc/os-release ]]; then
    (
        . /etc/os-release
        printf 'Operating system: %s\n' "${PRETTY_NAME:-Unknown}"
    )
fi

printf 'Uptime: %s\n' "$(uptime -p)"
printf 'Logical CPUs: %s\n' "$(getconf _NPROCESSORS_ONLN)"

awk '{
    printf "Load average (1 / 5 / 15 min): %s / %s / %s\n",
        $1, $2, $3
}' /proc/loadavg

section "CPU — ONE-SECOND SAMPLE"

read -r total_before idle_before < <(cpu_snapshot)
sleep 1
read -r total_after idle_after < <(cpu_snapshot)

awk \
    -v total_before="$total_before" \
    -v idle_before="$idle_before" \
    -v total_after="$total_after" \
    -v idle_after="$idle_after" '
    BEGIN {
        total_delta = total_after - total_before
        idle_delta = idle_after - idle_before

        if (total_delta <= 0 || idle_delta < 0 ||
            idle_delta > total_delta) {
            print "CPU usage: unavailable (invalid sample)"
            exit 1
        }

        printf "Non-idle CPU time: %.1f%%\n",
            100 * (total_delta - idle_delta) / total_delta
        print "Includes I/O wait and steal time."
    }
'

section "MEMORY"

awk '
    /^MemTotal:/     { total = $2 }
    /^MemFree:/      { free = $2 }
    /^MemAvailable:/ { available = $2; have_available = 1 }
    /^SwapTotal:/    { swap_total = $2 }
    /^SwapFree:/     { swap_free = $2 }

    END {
        if (total <= 0 || !have_available) {
            print "Memory statistics unavailable"
            exit 1
        }

        used = total - available

        printf "Total RAM:     %.1f MiB\n", total / 1024
        printf "Used RAM:      %.1f MiB (%.1f%%)\n",
            used / 1024, 100 * used / total
        printf "Available RAM: %.1f MiB (%.1f%%)\n",
            available / 1024, 100 * available / total
        printf "Free RAM:      %.1f MiB\n", free / 1024
        print "Used RAM is calculated as total minus available."

        if (swap_total > 0) {
            printf "Swap used:     %.1f / %.1f MiB (%.1f%%)\n",
                (swap_total - swap_free) / 1024,
                swap_total / 1024,
                100 * (swap_total - swap_free) / swap_total
        } else {
            print "Swap: not configured"
        }
    }
' /proc/meminfo

section "DISK SPACE — LOCAL FILESYSTEMS"

df -h -l -x tmpfs -x devtmpfs -x squashfs \
    --output=source,fstype,size,used,avail,pcent,target

section "TOP 5 PROCESSES BY CPU"

printf 'CPU percentages below are process lifetime averages.\n'

ps -eo pid,user,comm,pcpu,pmem --sort=-pcpu |
    awk 'NR <= 6 { print }'

section "TOP 5 PROCESSES BY MEMORY"

printf 'RSS is resident memory in KiB.\n'

ps -eo pid,user,comm,pmem,rss --sort=-rss |
    awk 'NR <= 6 { print }'

section "LAB SERVICES"

if command -v systemctl >/dev/null 2>&1; then
    if dnsmasq_state=$(systemctl is-active dnsmasq.service 2>/dev/null); then
        printf 'dnsmasq: %s\n' "$dnsmasq_state"
    else
        printf 'dnsmasq: %s\n' "${dnsmasq_state:-unavailable}"
    fi
else
    printf 'dnsmasq: systemctl is unavailable\n'
fi

if [[ -r /proc/sys/net/ipv4/ip_forward ]]; then
    read -r forwarding < /proc/sys/net/ipv4/ip_forward

    case "$forwarding" in
        1) printf 'IPv4 forwarding: enabled\n' ;;
        0) printf 'IPv4 forwarding: disabled\n' ;;
        *) printf 'IPv4 forwarding: unknown (%s)\n' "$forwarding" ;;
    esac
else
    printf 'IPv4 forwarding: unavailable\n'
fi

section "NETWORK INTERFACES"

if command -v ip >/dev/null 2>&1; then
    ip -br addr
else
    printf 'The ip command is unavailable.\n'
fi

printf '\nReport completed.\n'
