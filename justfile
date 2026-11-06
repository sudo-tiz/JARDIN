mash := justfile_directory() / "mash-playbook"
math := justfile_directory() / "math-playbook"
vault_file := env("ANSIBLE_VAULT_PASSWORD_FILE", justfile_directory() / "vault_pass")

export ANSIBLE_VAULT_PASSWORD_FILE := vault_file

default:
    @just --list

_check-vault:
    @[ -f "{{ vault_file }}" ] || { echo "No vault password: set ANSIBLE_VAULT_PASSWORD_FILE (file or script) or create vault_pass" >&2; exit 1; }

sync-inventory: _check-vault
    #!/usr/bin/env sh
    set -eu
    for pb in "{{ mash }}" "{{ math }}"; do
        mkdir -p "$pb/inventory/host_vars" "$pb/group_vars"
        cp -a inventory/hosts "$pb/inventory/hosts"
        cp -a inventory/host_vars/. "$pb/inventory/host_vars/"
        cp -a inventory/group_vars/. "$pb/group_vars/"
    done

update *args: math-update (mash-update args)

[working-directory: math]
math-update:
    git checkout -q main
    git pull -q --ff-only

[working-directory: mash]
mash-update *args:
    git checkout -q main
    just update {{ args }}

periodic-update: (math-full-upgrade "math_servers" "--extra-vars=apt_full_upgrade_reboot_if_required=true") mash-upgrade

mash-upgrade: mash-update mash-install-all mash-adjust-nextcloud-config

mash-install-all *args: (mash-run-tags "install-all" args)
mash-adjust-nextcloud-config *args: (mash-run-tags "adjust-nextcloud-config" args)

[working-directory: mash]
mash-run-tags tags *args: sync-inventory
    just run-tags {{ tags }} {{ args }}

math-bootstrap host="math_servers" *args: (_math "bootstrap" "--limit" host args)
math-full-upgrade host="math_servers" *args: (_math "full-upgrade" "--limit" host args)
math-reboot *args: (_math "reboot" args)
math-run-tags tags *args: (_math "run-tags" tags args)
math-create-vms vm="" *args: (_math "create-vms" quote(vm) args)

[working-directory: math]
_math recipe *args: sync-inventory
    just {{ recipe }} {{ args }}

list-tags: mash-list-tags math-list-tags
mash-list-tags: sync-inventory _mash-prepare (_list-tags mash)
math-list-tags: sync-inventory (_list-tags math)

[working-directory: mash]
_mash-prepare:
    just _prepare-files

_list-tags playbook:
    #!/usr/bin/env sh
    set -eu
    cd {{ playbook }}
    ansible-playbook -i "${ANSIBLE_INVENTORY:-inventory/hosts}" setup.yml --list-tags 2>/dev/null \
      | sed -n 's/.*TASK TAGS: \[\(.*\)\]/\1/p' | tr ',' '\n' | sed 's/^ *//' | sort -u | sed 's/^/  /'
