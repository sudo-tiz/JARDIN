# JARDIN

![Ansible](https://img.shields.io/badge/Ansible-EE0000?logo=ansible&logoColor=white)
![just](https://img.shields.io/badge/just-task_runner-orange)
![Debian](https://img.shields.io/badge/Debian-A81D33?logo=debian&logoColor=white)

Ansible self-hosting for a small server, driven by one `justfile` and one shared inventory.

```
JARDIN                     just + shared inventory
 ├─ mash-playbook            services: Docker, Traefik, PostgreSQL, borg…
 └─ math-playbook            host setup, firewall, mail relay, APT, KVM VMs
```

- [`mash-playbook/`](https://github.com/mother-of-all-self-hosting/mash-playbook): upstream MASH. Never edited here.
- [`math-playbook/`](math-playbook/README.md): our roles for what MASH doesn't cover.

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

`group_vars` hold formulas (`{{ x_hostname_label }}.{{ my_domain }}`), `host_vars` the private values.

## Groups

| Group | Runs |
|-------|------|
| `base`, `database`, `backup`, `home`, `media`, `supervision`, `vpn` | MASH services (children of `mash_servers`) |
| `math_servers` | math hosts |
| `vm_hosts`, `vms`, `firewall_hosts` | KVM VMs and firewall |

## Quick start

Requires `just`, the Ansible community package and `uv`.

```sh
git clone --recurse-submodules <url> && cd JARDIN
cp examples/inventory_hosts inventory/hosts
mkdir -p inventory/host_vars/<host>
cp examples/inventory_host_vars_example_vars.yml inventory/host_vars/<host>/vars.yml
# edit both, create + encrypt the vault.yml files with the vault_* variables
install -m 0600 /dev/null vault_pass   # then put the Vault password in it
just --dry-run <recipe>
```

## Recipes

```sh
just list-tags
just mash-install-all | mash-upgrade | mash-run-tags <tag>
just math-bootstrap [host] | math-full-upgrade [host] | math-reboot
just math-create-vms [vm]
just math-run-tags <tag>
just periodic-update
```

> [!WARNING]
> Playbooks change real machines: use `--check` and `--limit` first.

## Related

- [math-playbook](https://github.com/sudo-Tiz/math-playbook) — roles for what MASH doesn't cover
- [LARBUSTE](https://github.com/sudo-Tiz/LARBUSTE) — dotfiles, applied by the `larbuste` role
- [LARBRE](https://github.com/sudo-Tiz/LARBRE) — Arch Linux auto-setup
