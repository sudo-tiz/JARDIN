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

math-bootstrap host="math_servers" *args: sync-inventory
    cd {{ justfile_directory() }}/math-playbook && just bootstrap --limit {{ host }} {{ args }}

math-full-upgrade host="math_servers" *args: sync-inventory
    cd {{ justfile_directory() }}/math-playbook && just full-upgrade --limit {{ host }} {{ args }}

math-reboot *args: sync-inventory
    cd {{ justfile_directory() }}/math-playbook && just reboot {{ args }}

math-run-tags tags *args: sync-inventory
    cd {{ justfile_directory() }}/math-playbook && just run-tags {{ tags }} {{ args }}

math-create-vms vm="" *args: sync-inventory
    cd {{ justfile_directory() }}/math-playbook && just create-vms "{{ vm }}" {{ args }}

math-list-tags: sync-inventory (_list-tags "math-playbook")

mash-list-tags: sync-inventory
    cd {{ justfile_directory() }}/mash-playbook && just _setup-yml
    just --justfile {{ justfile() }} _list-tags mash-playbook

_list-tags playbook:
    #!/usr/bin/env sh
    set -eu
    cd {{ justfile_directory() }}/{{ playbook }}
    ansible-playbook -i "${ANSIBLE_INVENTORY:-inventory/hosts}" setup.yml --list-tags 2>/dev/null \
      | sed -n 's/.*TASK TAGS: \[\(.*\)\]/\1/p' | tr ',' '\n' | sed 's/^ *//' | sort -u | sed 's/^/  /'

list-tags:
    @echo "mash:"
    @just --justfile {{ justfile() }} mash-list-tags
    @echo "math:"
    @just --justfile {{ justfile() }} math-list-tags
