# Server playbooks

Ansible setup for a small self-hosted server, driven by one `justfile` and one shared inventory.

- [`mash-playbook/`](https://github.com/mother-of-all-self-hosting/mash-playbook): upstream MASH (Docker, Traefik, PostgreSQL, borg, self-hosted services). Never edited here.
- [`math-playbook/`](math-playbook/README.md): our roles for what MASH doesn't cover (host setup, mail relay, APT upgrades, firewall, KVM VMs).

Both are Git submodules. 

## Layout

| Path | Purpose |
|------|---------|
| `justfile` | Only entry point; syncs the inventory, then runs MASH or math. |
| `inventory/group_vars/` | Public shared variables per group. Vault values are only referenced. |
| `inventory/hosts`, `inventory/host_vars/` | Real hosts and private values. Git-ignored. |
| `**/vault.yml`, `vault_pass` | Ansible Vault files and password. Git-ignored. |
| `examples/` | Sanitized `hosts` and `host_vars`. |

`just sync-inventory` copies `inventory/` into both playbooks before every recipe. Don't edit the copies.

Groups: `base`, `database`, `backup`, `home`, `media`, `supervision`, `vpn` (MASH services, children of `mash_servers`); `math_servers` (math hosts); `vm_hosts`, `vms`, `firewall_hosts` (VMs and firewall). `group_vars` hold formulas (`{{ x_hostname_label }}.{{ my_domain }}`), `host_vars` the private values.

## Getting started

1. Install `just`, the Ansible community package and `uv`.
2. `git clone --recurse-submodules <url>`.
3. Copy `examples/inventory_hosts` to `inventory/hosts` and `examples/inventory_host_vars_example_vars.yml` to `inventory/host_vars/<host>/vars.yml`; edit them.
4. Create and encrypt the `vault.yml` files with the `vault_*` variables the `group_vars` reference.
5. Put the Vault password in `vault_pass` (mode `0600`).
6. Check first: `just --dry-run <recipe>`.

## Recipes

```sh
just list-tags
just mash-install-all | mash-upgrade | mash-run-tags <tag>
just math-bootstrap [host] | math-full-upgrade [host] | math-reboot
just math-create-vms [vm]
just math-run-tags <tag>
just periodic-update
```

Roles: [`math-playbook/README.md`](math-playbook/README.md). Playbooks change real machines: use `--check` and `--limit` first.
