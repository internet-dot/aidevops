#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025-2026 Marcus Quinn

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEDULERS_SCRIPT="${REPO_ROOT}/setup-modules/schedulers.sh"
TMP_DIR="$(mktemp -d)"

cleanup() {
	rm -rf "$TMP_DIR"
	return 0
}
trap cleanup EXIT

print_info() {
	return 0
}

print_warning() {
	return 0
}

systemctl() {
	local scope="${1:-}"
	local action="${2:-}"
	local flag="${3:-}"

	if [[ "$scope" == "--user" && "$action" == "daemon-reload" ]]; then
		return 0
	fi

	if [[ "$scope" == "--user" && "$action" == "enable" && "$flag" == "--now" ]]; then
		return 0
	fi

	return 1
}

export HOME="${TMP_DIR}/home"
export PATH="/usr/bin:/bin"
mkdir -p "$HOME/.aidevops/logs"

# shellcheck source=setup-modules/schedulers.sh
source "$SCHEDULERS_SCRIPT"

WRAPPER_SCRIPT="${TMP_DIR}/pulse-wrapper.sh"
touch "$WRAPPER_SCRIPT"
chmod +x "$WRAPPER_SCRIPT"

_install_pulse_systemd "aidevops-supervisor-pulse" "$WRAPPER_SCRIPT"

SERVICE_FILE="$HOME/.config/systemd/user/aidevops-supervisor-pulse.service"

if ! grep -q '^TimeoutStartSec=1800$' "$SERVICE_FILE"; then
	echo "expected TimeoutStartSec=1800 in ${SERVICE_FILE}" >&2
	exit 1
fi

if ! grep -q '^ExecStart=/bin/bash ' "$SERVICE_FILE"; then
	echo "expected ExecStart in ${SERVICE_FILE}" >&2
	exit 1
fi

printf 'PASS %s\n' "pulse systemd service includes TimeoutStartSec"
