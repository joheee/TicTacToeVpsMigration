#!/usr/bin/env bash
# Prints the bootstrap script embedded in the cloud-init template so it can be
# checked with shellcheck. Terraform template variables (${name}) are replaced
# with a placeholder, because they are filled in only at plan time.
#
# Usage: scripts/extract-bootstrap.sh [template] > bootstrap-vps.sh
set -euo pipefail

template="${1:-$(dirname "$0")/../cloud-init/cloud-config.yaml.tftpl}"

script=$(awk '
  /path: \/usr\/local\/sbin\/bootstrap-vps\.sh/ { found = 1; next }
  found && /content: \|/                         { in_body = 1; next }
  in_body && /^      /                           { sub(/^      /, ""); print; next }
  in_body && /^$/                                { print; next }
  in_body                                        { exit }
' "$template" | sed -E 's/\$\{[a-z_]+\}/placeholder/g')

if [ -z "$script" ]; then
  echo "bootstrap script not found in $template" >&2
  exit 1
fi

printf '%s\n' "$script"
