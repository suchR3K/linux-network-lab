# Linux Network Lab

A hands-on networking lab built with two Ubuntu Server virtual machines in VirtualBox. The project covers DHCP, DNS, IPv4 routing, NAT, and automated network checks using Bash and systemd.

## Architecture

```text
Internet
   |
VirtualBox NAT
   |
lab-server
enp0s3: IP assigned by VirtualBox DHCP
enp0s8: 192.168.50.1/24
   |
Internal Network: lab-net
   |
lab-client
enp0s8: 192.168.50.10/24 — DHCP reservation
```

The client's NAT adapter has its virtual cable disconnected. The client accesses the internet through `lab-server`.

## Technologies

- Ubuntu Server 24.04 LTS and VirtualBox
- Netplan and systemd-networkd
- dnsmasq for DHCP and DNS
- nftables for IPv4 forwarding rules and NAT
- Bash and systemd services and timers
- Git, SSH, and SCP
- Diagnostic tools: `ip`, `ping`, `dig`, `resolvectl`, and `journalctl`

## Network Configuration

| Setting | Value |
|---|---|
| Internal network | `lab-net` |
| Lab subnet | `192.168.50.0/24` |
| Server address | `192.168.50.1` |
| Client gateway and DNS | `192.168.50.1` |
| DHCP pool | `192.168.50.100–192.168.50.150` |
| Client DHCP reservation | `192.168.50.10` |
| DHCP lease duration | 1 hour |
| Local DNS record | `server.lab.test → 192.168.50.1` |
| Upstream DNS server | `1.1.1.1` |

DHCP operates on the isolated `lab-net` network.

dnsmasq resolves local names under `lab.test` and forwards external DNS queries to the upstream server. Client IPv4 traffic is forwarded through the server and masqueraded on `enp0s3`.

## Repository Structure

```text
configs/
├── client/
│   ├── 50-cloud-init.yaml
│   └── 60-lab-network.yaml
└── server/
    ├── 50-cloud-init.yaml
    ├── 60-lab-network.yaml
    ├── 90-lab-router.conf
    ├── lab.conf
    └── nftables.conf

scripts/
├── backup-config.sh
├── check-connectivity.sh
└── run-connectivity-check.sh

systemd/
├── lab-connectivity.service
└── lab-connectivity.timer
```

## Bash Scripts

### `check-connectivity.sh`

Runs on the client and checks:

- Whether the lab interface can be inspected.
- Whether the server responds to ICMP through the lab interface.
- Whether the system resolves `server.lab.test` to the expected IPv4 address.
- Whether the default IPv4 route uses the expected gateway and interface.

Returns `0` on success and `1` when a check fails. Checks stop at the first failure.

### `run-connectivity-check.sh`

Runs the connectivity script and appends its output to:

```text
logs/connectivity.log
```

Each entry includes a timestamp, diagnostic output, and the check's exit code. The wrapper preserves that exit code.

The `logs/` directory is excluded from Git.

### `backup-config.sh`

Runs on the server with `sudo` and creates a compressed configuration archive in:

```text
/var/backups/linux-network-lab/
```

The archive includes:

- Netplan configuration.
- dnsmasq configuration.
- nftables rules.
- The IPv4 forwarding setting.

This is a configuration backup, not a full VM backup.

## Automated Checks

`lab-connectivity.timer` triggers `lab-connectivity.service` approximately once per minute.

The service runs the reporting script as user `julia`. It is a `oneshot` service, so an inactive state after successful execution is expected.

After configuring the lab and installing the unit files, useful commands on the client include:

```bash
systemctl list-timers --all lab-connectivity.timer
```

```bash
systemctl status lab-connectivity.service --no-pager
```

```bash
tail -n 25 ~/projects/linux-network-lab/logs/connectivity.log
```

To run a check manually:

```bash
cd ~/projects/linux-network-lab
./scripts/run-connectivity-check.sh
echo $?
```

## Verified Scenarios

| Scenario | Observed result |
|---|---|
| Dynamic DHCP allocation | Client received `192.168.50.117/24` from the configured pool |
| DHCP exchange | DISCOVER, OFFER, REQUEST, and ACK appeared in server logs |
| DHCP reservation | Client received `192.168.50.10/24` |
| Reservation change | Server rejected renewal of the previous address; cycling the client interface obtained the reserved address |
| Client-to-server connectivity | Four ping replies with 0% packet loss |
| Local DNS | `server.lab.test` resolved to `192.168.50.1` |
| External DNS | Internet domain names resolved through the lab DNS server |
| Routing and NAT | Client reached an external IPv4 address through the server |
| Client NAT disconnection | Internet access continued through the lab server |
| Firewall counters | Forwarding and NAT counters increased during traffic tests |
| Network failure detection | Disabling the client lab interface produced `FAIL` and exit code `1` |
| DNS misconfiguration detection | An incorrect DNS record produced `FAIL` and exit code `1` |
| Recovery checks | Restoring connectivity and DNS produced `PASS` and exit code `0` |
| Scheduled execution | The timer generated log entries automatically |
| Client restart | DHCP, DNS, and scheduled checks resumed |
| Server restart | DHCP/DNS service, forwarding, and NAT configuration resumed |
| Configuration backup | Archive creation and archive listing completed successfully |

Backup extraction and restoration have **not yet been tested**.

## Using the Configuration Files

This repository contains configuration snapshots from a working lab. It is not an automated installer.

Before reusing the files, adjust:

- Network interface names.
- The client MAC address in the DHCP reservation.
- IP addresses and subnet ranges.
- Usernames and absolute paths in the systemd service.

Files under `configs/` are copies. Editing them does not update the running system.

The server configuration files correspond to:

| Repository file | System location |
|---|---|
| `configs/server/50-cloud-init.yaml` | `/etc/netplan/50-cloud-init.yaml` |
| `configs/server/60-lab-network.yaml` | `/etc/netplan/60-lab-network.yaml` |
| `configs/server/lab.conf` | `/etc/dnsmasq.d/lab.conf` |
| `configs/server/nftables.conf` | `/etc/nftables.conf` |
| `configs/server/90-lab-router.conf` | `/etc/sysctl.d/90-lab-router.conf` |

Client Netplan files belong under `/etc/netplan/`. Service and timer files belong under `/etc/systemd/system/`.

The supplied nftables configuration contains `flush ruleset` and replaces existing nftables rules when loaded. Review it before applying it outside this dedicated lab.

## Troubleshooting Experience

Issues investigated during the project included:

- A disconnected virtual network cable causing `NO-CARRIER`.
- A client retaining its previous DHCP address during a reservation change.
- A Bash variable name mismatch causing an `unbound variable` error.

Diagnostics used interface state, service status, DHCP logs, routing tables, exit codes, and nftables counters.

