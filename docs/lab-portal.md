# Lab Portal

A static English-language portal for the Linux Network Lab, served by Nginx and updated over SSH with rsync. No frontend dependencies or build step are required.

## Files

```text
site/index.html
site/styles.css
configs/nginx/lab-portal.conf
scripts/deploy-site.sh
.github/workflows/lab-portal.yml
docs/lab-portal.md
```

Merge these files into the existing repository directories. Keep the existing README, scripts and workflows. Do not upload a containing `lab-portal` folder: the paths above are relative to the repository root.

## What is automated

GitHub Actions checks Bash syntax and ShellCheck, starts Nginx on an isolated Ubuntu runner and verifies the page, CSS, health endpoint, missing-page response and hidden-file blocking. It also checks that `/healthz` returns 503 when the index file is missing.

CI does not deploy to the lab, test SSH or test local DNS. The portal describes the intended architecture, not live service status. `/healthz` serves the index file when present; it does not check DHCP, DNS or Internet access.

Delivery status: files prepared; no successful CI run, VM deployment or browser visual verification has been confirmed yet. Local Bash execution was unavailable in the Windows sandbox. Record actual results after running the checks rather than marking them PASS in advance.

## Preview without a VM

Open `site/index.html` in a Windows browser. It loads the adjacent `styles.css`. This previews the design only, not Nginx behavior.

## One-time server setup (later)

Target: the existing Ubuntu lab-server, user `julia`, lab address `192.168.50.1`. This is an internal HTTP lab, not a public HTTPS deployment. SSH must already work from the deployment machine. Do not add Internet port forwarding for this exercise.

On **lab-server**, from your updated repository checkout:

```bash
sudo apt-get update
sudo apt-get install -y nginx rsync
sudo install -d -o julia -g julia -m 755 /var/www/lab-portal
install -m 644 site/index.html site/styles.css /var/www/lab-portal/
sudo install -m 644 configs/nginx/lab-portal.conf /etc/nginx/sites-available/lab-portal.conf
sudo ln -s /etc/nginx/sites-available/lab-portal.conf /etc/nginx/sites-enabled/lab-portal.conf
sudo nginx -t
```

If the symlink already exists, inspect it instead of recreating it. Proceed only after `nginx -t` succeeds:

```bash
sudo systemctl enable --now nginx
sudo systemctl reload nginx
```

The dedicated server_name selects this site without removing the existing default site. If another service already uses port 80, resolve that conflict before starting Nginx. If you later enable an input firewall, allow HTTP from the lab subnet; do not flush existing firewall rules.

### Local DNS

On **lab-server**, edit the existing `/etc/dnsmasq.d/lab.conf` and add this line once, keeping all other DHCP and DNS settings:

```ini
host-record=portal.lab.test,192.168.50.1
```

Validate first, then restart only when validation succeeds:

```bash
sudo dnsmasq --test && sudo systemctl restart dnsmasq
```

This restart briefly interrupts the lab's DNS/DHCP service. The address resolves on clients using this lab DNS server; Windows will not automatically know the name.

## Deploy changes

On **lab-client**, install rsync and the SSH client if needed:

```bash
sudo apt-get install -y rsync openssh-client
```

Use an updated checkout containing the portal files on lab-client. From its repository root:

```bash
bash scripts/deploy-site.sh --dry-run
bash scripts/deploy-site.sh
```

The script uses `julia@192.168.50.1`, SSH port 22 and `/var/www/lab-portal/`. Verify the server host key when first connecting. Normal SSH password/key authentication applies; the script does not store passwords or disable host verification.

Dry run still contacts the server but transfers no files. Deployment updates only `index.html` and `styles.css`, using checksums to detect content changes, and sets file permissions to 644. It does not remove remote files or restart Nginx. New assets must be explicitly added to the script. Transfers are not an atomic multi-file release; use this simple approach for the lab, not zero-downtime production releases. Re-deploy an earlier Git revision to restore an earlier version of these two files.

## Verify from lab-client

```bash
getent hosts portal.lab.test
curl -fsS http://portal.lab.test/ -o /dev/null
curl -fsS http://portal.lab.test/healthz -o /dev/null
bash scripts/check-http.sh -- http://portal.lab.test/healthz
```

The final command uses the separate Bash toolkit. A successful curl command exits with code 0. A GUI browser on the lab network can open `http://portal.lab.test`; a console-only VM can use curl. To test HTTP before DNS is configured:

```bash
curl -fsS -H 'Host: portal.lab.test' http://192.168.50.1/
```

Suggested evidence: a browser screenshot, successful DNS lookup, HTTP response, rsync dry-run output and a green CI run. Keep secrets and SSH keys out of screenshots and Git.

## References

- [Nginx core module: server_name, root and try_files](https://nginx.org/en/docs/http/ngx_http_core_module.html)
- [Official rsync manual](https://download.samba.org/pub/rsync/rsync.1)
