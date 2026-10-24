# Server playbooks

This public repository contains playbooks, shared non-Vault `inventory/group_vars`, sanitized host examples, and the root `justfile`. The real `inventory/hosts`, `inventory/host_vars/`, Vault files, and `vault_pass` are ignored; no Vault files are included in the examples.

Copy `examples/inventory/hosts` and `examples/inventory/host_vars/example/vars.yml` into the local `inventory/`, then replace the example host and values. Create the required Ansible Vault files locally. Keep `vault_pass` at the repository root with mode `0600`. The root `justfile` exports `ANSIBLE_VAULT_PASSWORD_FILE` and copies the shared inventory to both submodules before running either playbook.
