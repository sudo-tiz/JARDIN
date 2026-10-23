export ANSIBLE_VAULT_PASSWORD_FILE := justfile_directory() + "/vault_pass"

default:
    @just --list

sync-inventory:
    #!/usr/bin/env sh
    set -eu
    root="{{ justfile_directory() }}"
    mkdir -p "$root/mash-playbook/inventory/host_vars" "$root/mash-playbook/group_vars"
    mkdir -p "$root/math-playbook/inventory/host_vars" "$root/math-playbook/inventory/group_vars"
    cp -a "$root/inventory/hosts" "$root/mash-playbook/inventory/hosts"
    cp -a "$root/inventory/hosts" "$root/math-playbook/inventory/hosts"
    cp -a "$root/inventory/host_vars/." "$root/mash-playbook/inventory/host_vars/"
    cp -a "$root/inventory/host_vars/." "$root/math-playbook/inventory/host_vars/"
    cp -a "$root/inventory/group_vars/." "$root/mash-playbook/group_vars/"
    cp -a "$root/inventory/group_vars/." "$root/math-playbook/inventory/group_vars/"

mash-install-all *args: sync-inventory
    cd {{ justfile_directory() }}/mash-playbook && just install-all {{ args }}

mash-adjust-nextcloud-config *args: sync-inventory
    cd {{ justfile_directory() }}/mash-playbook && just run-tags adjust-nextcloud-config {{ args }}

mash-run-tags tags *args: sync-inventory
    cd {{ justfile_directory() }}/mash-playbook && just run-tags {{ tags }} {{ args }}

mash-update *args:
    cd {{ justfile_directory() }}/mash-playbook && just update {{ args }}

mash-upgrade: mash-update mash-install-all mash-adjust-nextcloud-config

periodic-update: sync-inventory
    cd {{ justfile_directory() }}/math-playbook && just full-upgrade --extra-vars=apt_full_upgrade_reboot_if_required=true
    just --justfile {{ justfile() }} mash-upgrade

_check-uv:
    #!/usr/bin/env sh
    command -v uv >/dev/null && exit 0
    echo "uv is required by mash-optimize (it provides the Python 'regex' module)." >&2
    echo "Install it: curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
    echo "or use your package manager (e.g. 'pacman -S uv', 'brew install uv')." >&2
    exit 1

mash-optimize: _check-uv sync-inventory
    #!/usr/bin/env sh
    set -eu
    cd {{ justfile_directory() }}/mash-playbook
    uv run --with regex --with pyyaml -- just _optimize-for-var-paths $(find inventory/host_vars group_vars -name vars.yml -exec readlink -f {} \;)

mash-optimize-reset:
    cd {{ justfile_directory() }}/mash-playbook && just optimize-reset

math-bootstrap *args: sync-inventory
    cd {{ justfile_directory() }}/math-playbook && just bootstrap {{ args }}

math-full-upgrade *args: sync-inventory
    cd {{ justfile_directory() }}/math-playbook && just full-upgrade {{ args }}

math-reboot *args: sync-inventory
    cd {{ justfile_directory() }}/math-playbook && just reboot {{ args }}

math-run-tags tags *args: sync-inventory
    cd {{ justfile_directory() }}/math-playbook && just run-tags {{ tags }} {{ args }}
