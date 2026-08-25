# Establish a wireguard tunnel to a peer

**Play** · [`site.yml`](site.yml) → role [`peer`](roles/peer/)
**Runs** · locally, on the host it configures
**Config** · [`group_vars/all/vars.yml`](group_vars/all/vars.yml)
**Deployment** · `group_vars/all/local.yml` — gitignored, from `local.yml.example`

Establishes a WireGuard tunnel from **this host** to a peer at another provider,
where the tunnel's own packets travel inside a commercial-VPN tunnel this host
already has — so the peer's provider sees a VPN exit address rather than this
machine's own. Plus a pinned SSH configuration, a SOCKS proxy so a browser here
connects from the peer, and a fail-closed nftables table of its own.

```
   admin ────────> this host ──outer tunnel──> VPN exit ──> peer host
                       │                                    (another provider)
                       └── wg-remote (10.90.0.1) ─────────> 10.90.0.2
                           encapsulated inside the outer tunnel
```

## Running it

```bash
$ sudo -i
$ ./scripts/install-ansible.sh
$ ansible-playbook -i inventory site.yml
```

Root is needed: `/etc/wireguard`, systemd units, nftables, ip rules and
apt.

## The peer side

Two accounts on the peer:

- **`peer_ssh_user`** — It requires passwordless sudo. root works.
- **`peer_user`** — the play creates it, unprivileged. It carries two authorized
  keys: the forward-only key the SOCKS proxy uses (it can only forward ports),
  and the shell key

The play connects as `peer_ssh_user`, escalates with its sudo, and does the
rest: creates `peer_user`, installs `wireguard-tools`, writes the tunnel config
and unit, and authorizes the forward-only key on `peer_user`.

## Browsing through the peer

`socks-peer.service` holds `ssh -N -D 127.0.0.1:1080 peer-tunnel` open as the
unprivileged account, and a browser profile points at it. The browser runs
**here**; its connections are made from the **peer**.

## Displaying applications: xpra, not raw X11

[**xpra**](https://xpra.org) is "screen for X": rather than forwarding the X11
protocol, it runs its own X server **on the peer**, starts the application
against it there, and ships the rendered window contents back as compressed
image/video streams. Windows are rootless, so they land on this host's desktop
rather than inside a nested remote desktop.

```bash
xpra start ssh:peer --start=xterm       # needs xpra on the peer too
```

## Operate

```bash
sudo wg show                                 # both tunnels, handshake ages
ip route get <peer-ip>                       # must leave by the outer interface
ip rule list                                 # prio 90: to 10.90.0.0/24 lookup main
sudo nft list table inet peer_killswitch     # per-rule counters
systemctl status peer-killswitch wg-quick@wg-remote socks-peer

# What the internet sees through the proxy — must be the peer's address
sudo -u <account> curl -sS --socks5-hostname 127.0.0.1:1080 https://am.i.mullvad.net/json
```
