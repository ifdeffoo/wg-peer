#!/usr/bin/env bash
# Install ansible-core on this host, for this repo.
#
# Usage:
#   scripts/install-ansible.sh
#   ANSIBLE_VERSION='2.17.*' scripts/install-ansible.sh   # override the pin
set -euo pipefail

# Guard against a half-configured locale
export LC_ALL="${LC_ALL:-C.UTF-8}"

ANSIBLE_VERSION="${ANSIBLE_VERSION:-2.17.*}"
export PATH="$HOME/.local/bin:$PATH"

if ! command -v uv >/dev/null 2>&1; then
  echo "==> Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

echo "==> Installing ansible-core ${ANSIBLE_VERSION}"
uv tool install --force "ansible-core==${ANSIBLE_VERSION}"

echo
echo "Done: $(ansible --version | head -1)"
echo "If 'ansible' isn't found in a new shell, add ~/.local/bin to your PATH."
