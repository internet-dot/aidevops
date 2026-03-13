#!/usr/bin/env bash
# test-pulse-wrapper-lock.sh — Unit tests for acquire_wrapper_lock() (GH#4409)
#
# Tests the wrapper-level PID lock that prevents concurrent pulse-wrapper.sh
# instances during the setup/prefetch phase.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
WRAPPER_SCRIPT="${SCRIPT_DIR}/../pulse-wrapper.sh"

readonly TEST_RED='\033[0;31m'
readonly TEST_GREEN='\033[0;32m'
readonly TEST_RESET='\033[0m'

TESTS_RUN=0
TESTS_FAILED=0
TEST_ROOT=""
ORIGINAL_HOME="${HOME}"

print_result() {
	local test_name="$1"
	local passed="$2"
	local message="${3:-}"
	TESTS_RUN=$((TESTS_RUN + 1))

	if [[ "$passed" -eq 0 ]]; then
		printf '%bPASS%b %s\n' "$TEST_GREEN" "$TEST_RESET" "$test_name"
		return 0
	fi

	printf '%bFAIL%b %s\n' "$TEST_RED" "$TEST_RESET" "$test_name"
	if [[ -n "$message" ]]; then
		printf '       %s\n' "$message"
	fi
	TESTS_FAILED=$((TESTS_FAILED + 1))
	return 0
}

setup_test_env() {
	TEST_ROOT=$(mktemp -d)
	export HOME="${TEST_ROOT}/home"
	mkdir -p "${HOME}/.aidevops/logs"
	# shellcheck source=/dev/null
	source "$WRAPPER_SCRIPT"
	return 0
}

teardown_test_env() {
	# Clear the EXIT trap registered by acquire_wrapper_lock before removing
	# the temp directory — otherwise the trap fires after rm -rf and produces
	# a harmless but noisy "No such file or directory" error.
	trap - EXIT
	export HOME="$ORIGINAL_HOME"
	if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
		rm -rf "$TEST_ROOT"
	fi
	return 0
}

# ─── Tests ────────────────────────────────────────────────────────────────────

test_lock_acquired_when_no_file() {
	# No lock file exists — should acquire immediately
	local lock_file="${HOME}/.aidevops/logs/pulse-wrapper.lock"
	rm -f "$lock_file"

	acquire_wrapper_lock
	local rc=$?

	local content
	content=$(cat "$lock_file" 2>/dev/null || echo "")
	local is_our_pid=0
	[[ "$content" == "$$" ]] && is_our_pid=1

	print_result "acquire_wrapper_lock: no file → acquired" \
		$((rc != 0 || is_our_pid != 1)) \
		"rc=${rc}, content='${content}', expected PID=$$"
}

test_lock_acquired_when_idle_sentinel() {
	# Lock file contains IDLE sentinel — should acquire
	local lock_file="${HOME}/.aidevops/logs/pulse-wrapper.lock"
	echo "IDLE:2026-03-13T00:00:00Z" >"$lock_file"

	acquire_wrapper_lock
	local rc=$?

	local content
	content=$(cat "$lock_file" 2>/dev/null || echo "")
	local is_our_pid=0
	[[ "$content" == "$$" ]] && is_our_pid=1

	print_result "acquire_wrapper_lock: IDLE sentinel → acquired" \
		$((rc != 0 || is_our_pid != 1)) \
		"rc=${rc}, content='${content}', expected PID=$$"
}

test_lock_acquired_when_empty_file() {
	# Lock file is empty — should acquire
	local lock_file="${HOME}/.aidevops/logs/pulse-wrapper.lock"
	: >"$lock_file"

	acquire_wrapper_lock
	local rc=$?

	local content
	content=$(cat "$lock_file" 2>/dev/null || echo "")
	local is_our_pid=0
	[[ "$content" == "$$" ]] && is_our_pid=1

	print_result "acquire_wrapper_lock: empty file → acquired" \
		$((rc != 0 || is_our_pid != 1)) \
		"rc=${rc}, content='${content}', expected PID=$$"
}

test_lock_acquired_when_stale_pid() {
	# Lock file contains a PID that is no longer running — should acquire
	local lock_file="${HOME}/.aidevops/logs/pulse-wrapper.lock"

	# Use a PID that is guaranteed not to exist: find a dead PID by
	# checking a high number that is almost certainly unused.
	local dead_pid=99999
	# Verify it's actually dead (skip test if somehow alive)
	if kill -0 "$dead_pid" 2>/dev/null; then
		printf 'SKIP test_lock_acquired_when_stale_pid: PID %d is alive\n' "$dead_pid"
		return 0
	fi

	echo "$dead_pid" >"$lock_file"

	acquire_wrapper_lock
	local rc=$?

	local content
	content=$(cat "$lock_file" 2>/dev/null || echo "")
	local is_our_pid=0
	[[ "$content" == "$$" ]] && is_our_pid=1

	print_result "acquire_wrapper_lock: stale PID → acquired" \
		$((rc != 0 || is_our_pid != 1)) \
		"rc=${rc}, content='${content}', expected PID=$$"
}

test_lock_blocked_when_live_pid() {
	# Lock file contains our own PID (simulates a live concurrent wrapper).
	# acquire_wrapper_lock should return 1 (blocked).
	# Run in a subshell so the EXIT trap registered by acquire_wrapper_lock
	# does not interfere with the parent test process.
	local lock_file="${HOME}/.aidevops/logs/pulse-wrapper.lock"

	# Use $$ (current process) as the "live" PID — it's definitely alive
	echo "$$" >"$lock_file"

	local rc=0
	# Run in a subshell with WRAPPER_LOCKFILE overridden to the test file.
	# The subshell's EXIT trap writes the IDLE sentinel to the test file,
	# which is harmless — the parent test process is unaffected.
	(
		WRAPPER_LOCKFILE="$lock_file"
		acquire_wrapper_lock
	) || rc=$?

	print_result "acquire_wrapper_lock: live PID → blocked (rc=1)" \
		$((rc != 1)) \
		"expected rc=1, got rc=${rc}"
}

test_lock_acquired_when_unrecognised_content() {
	# Lock file contains garbage — should treat as idle and acquire
	local lock_file="${HOME}/.aidevops/logs/pulse-wrapper.lock"
	echo "not-a-pid" >"$lock_file"

	acquire_wrapper_lock
	local rc=$?

	local content
	content=$(cat "$lock_file" 2>/dev/null || echo "")
	local is_our_pid=0
	[[ "$content" == "$$" ]] && is_our_pid=1

	print_result "acquire_wrapper_lock: unrecognised content → acquired" \
		$((rc != 0 || is_our_pid != 1)) \
		"rc=${rc}, content='${content}', expected PID=$$"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
	setup_test_env

	test_lock_acquired_when_no_file
	test_lock_acquired_when_idle_sentinel
	test_lock_acquired_when_empty_file
	test_lock_acquired_when_stale_pid
	test_lock_blocked_when_live_pid
	test_lock_acquired_when_unrecognised_content

	teardown_test_env

	echo ""
	if [[ "$TESTS_FAILED" -eq 0 ]]; then
		printf '%bAll %d tests passed%b\n' "$TEST_GREEN" "$TESTS_RUN" "$TEST_RESET"
		return 0
	else
		printf '%b%d/%d tests FAILED%b\n' "$TEST_RED" "$TESTS_FAILED" "$TESTS_RUN" "$TEST_RESET"
		return 1
	fi
}

main "$@"
