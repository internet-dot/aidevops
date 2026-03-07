#!/usr/bin/env bash
# gh-token-helper.sh - Scoped, short-lived GitHub tokens for worker agents (t1412.2)
#
# Creates repo-scoped GitHub tokens for headless worker sessions so each worker
# operates with minimal permissions that expire after the session. Reduces blast
# radius if a worker is compromised via prompt injection.
#
# Two modes:
#   1. GitHub App installation tokens (preferred) — repo-scoped, 1h TTL, enforced
#      by GitHub. Requires one-time GitHub App installation by the user.
#   2. Fallback: inherits the user's existing `gh auth token` but logs a warning.
#      The token is NOT scoped — isolation is advisory, not enforced by GitHub.
#
# Usage:
#   gh-token-helper.sh create --repo <owner/repo> [--permissions <json>] [--ttl <minutes>]
#   gh-token-helper.sh revoke --token-file <path>
#   gh-token-helper.sh status
#   gh-token-helper.sh setup   # Interactive GitHub App setup guide
#   gh-token-helper.sh help
#
# Environment:
#   AIDEVOPS_GH_APP_ID         — GitHub App ID (from App settings)
#   AIDEVOPS_GH_APP_PRIVATE_KEY — Path to PEM private key file
#   AIDEVOPS_GH_APP_INSTALL_ID — Installation ID (auto-detected if not set)
#
# Integration:
#   Called by dispatch.sh before spawning a worker. The token is written to a
#   temp file (0600 perms) and the path is passed to the worker via
#   GH_TOKEN_FILE env var. The worker's fake HOME (t1412.1) uses this token
#   for `gh` CLI auth. On worker exit, the token file is cleaned up.
#
# Author: AI DevOps Framework
# Version: 1.0.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit
source "${SCRIPT_DIR}/shared-constants.sh"

# Configuration
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/aidevops"
readonly GH_APP_CONFIG_FILE="${CONFIG_DIR}/gh-app.json"
readonly TOKEN_DIR="${HOME}/.aidevops/.agent-workspace/tmp/gh-tokens"
readonly DEFAULT_TTL_MINUTES=60
readonly DEFAULT_PERMISSIONS='{"contents":"write","pull_requests":"write","issues":"write"}'

# =============================================================================
# Logging
# =============================================================================

log_info() {
	local msg="$1"
	echo -e "${BLUE}[gh-token]${NC} $msg"
	return 0
}

log_warn() {
	local msg="$1"
	echo -e "${YELLOW}[gh-token]${NC} $msg" >&2
	return 0
}

log_error() {
	local msg="$1"
	echo -e "${RED}[gh-token]${NC} $msg" >&2
	return 0
}

log_success() {
	local msg="$1"
	echo -e "${GREEN}[gh-token]${NC} $msg"
	return 0
}

# =============================================================================
# GitHub App JWT generation
# =============================================================================

# Generate a JWT for GitHub App authentication.
# Requires: openssl (for RS256 signing)
# Args: $1 = app_id, $2 = private_key_path
# Outputs: JWT string on stdout
generate_jwt() {
	local app_id="$1"
	local key_path="$2"

	if [[ ! -f "$key_path" ]]; then
		log_error "Private key file not found: $key_path"
		return 1
	fi

	# JWT header and payload
	local now
	now=$(date +%s)
	local iat=$((now - 60))  # 60s clock skew buffer
	local exp=$((now + 600)) # 10 minute max for App JWTs

	local header
	header=$(printf '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

	local payload
	payload=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$iat" "$exp" "$app_id" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

	local unsigned="${header}.${payload}"

	# Sign with RS256
	local signature
	signature=$(printf '%s' "$unsigned" | openssl dgst -sha256 -sign "$key_path" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

	printf '%s.%s' "$unsigned" "$signature"
	return 0
}

# =============================================================================
# GitHub App configuration
# =============================================================================

# Load GitHub App configuration from env vars or config file.
# Sets: _GH_APP_ID, _GH_APP_KEY_PATH, _GH_APP_INSTALL_ID
# Returns: 0 if App is configured, 1 if not
load_app_config() {
	_GH_APP_ID="${AIDEVOPS_GH_APP_ID:-}"
	_GH_APP_KEY_PATH="${AIDEVOPS_GH_APP_PRIVATE_KEY:-}"
	_GH_APP_INSTALL_ID="${AIDEVOPS_GH_APP_INSTALL_ID:-}"

	# Try config file if env vars not set
	if [[ -z "$_GH_APP_ID" && -f "$GH_APP_CONFIG_FILE" ]]; then
		_GH_APP_ID=$(jq -r '.app_id // empty' "$GH_APP_CONFIG_FILE" 2>/dev/null) || true
		_GH_APP_KEY_PATH=$(jq -r '.private_key_path // empty' "$GH_APP_CONFIG_FILE" 2>/dev/null) || true
		_GH_APP_INSTALL_ID=$(jq -r '.installation_id // empty' "$GH_APP_CONFIG_FILE" 2>/dev/null) || true
	fi

	# Validate
	if [[ -z "$_GH_APP_ID" || -z "$_GH_APP_KEY_PATH" ]]; then
		return 1
	fi

	if [[ ! -f "$_GH_APP_KEY_PATH" ]]; then
		log_warn "GitHub App private key not found at: $_GH_APP_KEY_PATH"
		return 1
	fi

	return 0
}

# Auto-detect installation ID for a given repo.
# Args: $1 = owner/repo
# Returns: installation ID on stdout, or empty on failure
detect_installation_id() {
	local repo_slug="$1"
	local owner="${repo_slug%%/*}"

	# Generate JWT for App auth
	local jwt
	jwt=$(generate_jwt "$_GH_APP_ID" "$_GH_APP_KEY_PATH") || return 1

	# List installations and find the one for this owner
	local installations
	installations=$(curl -sf \
		-H "Authorization: Bearer ${jwt}" \
		-H "Accept: application/vnd.github+json" \
		"https://api.github.com/app/installations" 2>/dev/null) || {
		log_warn "Failed to list GitHub App installations"
		return 1
	}

	local install_id
	install_id=$(printf '%s' "$installations" | jq -r \
		--arg owner "$owner" \
		'.[] | select(.account.login == $owner) | .id' 2>/dev/null | head -1) || true

	if [[ -z "$install_id" || "$install_id" == "null" ]]; then
		log_warn "No GitHub App installation found for owner: $owner"
		return 1
	fi

	printf '%s' "$install_id"
	return 0
}

# =============================================================================
# Token creation
# =============================================================================

# Create a scoped GitHub token for a specific repo.
# Args: --repo <owner/repo> [--permissions <json>] [--ttl <minutes>]
# Outputs: JSON with token_file path and expiry on stdout
cmd_create() {
	local repo_slug=""
	local permissions="$DEFAULT_PERMISSIONS"
	local ttl_minutes="$DEFAULT_TTL_MINUTES"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--repo | -r)
			repo_slug="$2"
			shift 2
			;;
		--permissions | -p)
			permissions="$2"
			shift 2
			;;
		--ttl | -t)
			ttl_minutes="$2"
			shift 2
			;;
		*)
			shift
			;;
		esac
	done

	if [[ -z "$repo_slug" ]]; then
		log_error "Usage: gh-token-helper.sh create --repo <owner/repo>"
		return 1
	fi

	# Validate repo slug format
	if [[ ! "$repo_slug" =~ ^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$ ]]; then
		log_error "Invalid repo slug: $repo_slug (expected owner/repo)"
		return 1
	fi

	local repo_name="${repo_slug#*/}"

	# Ensure token directory exists with secure permissions
	mkdir -p "$TOKEN_DIR"
	chmod 700 "$TOKEN_DIR"

	# Try GitHub App token first (preferred — enforced scoping)
	if load_app_config; then
		local install_id="$_GH_APP_INSTALL_ID"

		# Auto-detect installation ID if not configured
		if [[ -z "$install_id" ]]; then
			install_id=$(detect_installation_id "$repo_slug") || true
		fi

		if [[ -n "$install_id" ]]; then
			local token_result
			token_result=$(create_app_token "$install_id" "$repo_name" "$permissions") || true

			if [[ -n "$token_result" ]]; then
				local token expires_at
				token=$(printf '%s' "$token_result" | jq -r '.token // empty' 2>/dev/null) || true
				expires_at=$(printf '%s' "$token_result" | jq -r '.expires_at // empty' 2>/dev/null) || true

				if [[ -n "$token" && "$token" != "null" ]]; then
					# Write token to secure temp file
					local token_file
					token_file=$(write_token_file "$token" "$repo_slug" "$expires_at" "app")

					log_success "Created scoped App token for $repo_slug (expires: $expires_at)"
					printf '{"token_file":"%s","expires_at":"%s","mode":"app","repo":"%s"}\n' \
						"$token_file" "$expires_at" "$repo_slug"
					return 0
				fi
			fi
			log_warn "Failed to create App installation token, falling back"
		fi
	fi

	# Fallback: use existing gh auth token (not scoped — advisory only)
	create_fallback_token "$repo_slug"
	return $?
}

# Create a GitHub App installation token via API.
# Args: $1 = installation_id, $2 = repo_name, $3 = permissions_json
# Outputs: API response JSON on stdout
create_app_token() {
	local install_id="$1"
	local repo_name="$2"
	local permissions="$3"

	local jwt
	jwt=$(generate_jwt "$_GH_APP_ID" "$_GH_APP_KEY_PATH") || return 1

	local request_body
	request_body=$(jq -n \
		--arg repo "$repo_name" \
		--argjson perms "$permissions" \
		'{repositories: [$repo], permissions: $perms}')

	local response
	response=$(curl -sf \
		-X POST \
		-H "Authorization: Bearer ${jwt}" \
		-H "Accept: application/vnd.github+json" \
		"https://api.github.com/app/installations/${install_id}/access_tokens" \
		-d "$request_body" 2>/dev/null) || {
		log_warn "GitHub App token creation API call failed"
		return 1
	}

	# Verify response has a token
	local token_check
	token_check=$(printf '%s' "$response" | jq -r '.token // empty' 2>/dev/null) || true
	if [[ -z "$token_check" ]]; then
		local error_msg
		error_msg=$(printf '%s' "$response" | jq -r '.message // "unknown error"' 2>/dev/null) || true
		log_warn "GitHub App token creation failed: $error_msg"
		return 1
	fi

	printf '%s' "$response"
	return 0
}

# Create a fallback token using the user's existing gh auth.
# NOT scoped by GitHub — isolation is advisory only.
# Args: $1 = repo_slug
create_fallback_token() {
	local repo_slug="$1"

	# Get the user's current gh token
	local user_token
	user_token=$(gh auth token 2>/dev/null) || {
		log_error "No GitHub authentication found. Run 'gh auth login' first."
		return 1
	}

	if [[ -z "$user_token" ]]; then
		log_error "gh auth token returned empty. Run 'gh auth login' first."
		return 1
	fi

	# Calculate expiry (advisory — token doesn't actually expire)
	local expires_at
	expires_at=$(date -u -v+"${DEFAULT_TTL_MINUTES}M" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null ||
		date -u -d "+${DEFAULT_TTL_MINUTES} minutes" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null ||
		echo "unknown")

	# Write token to secure temp file
	local token_file
	token_file=$(write_token_file "$user_token" "$repo_slug" "$expires_at" "fallback")

	log_warn "Using fallback token (not scoped by GitHub). Install a GitHub App for enforced scoping."
	log_warn "Run 'gh-token-helper.sh setup' for GitHub App installation guide."
	printf '{"token_file":"%s","expires_at":"%s","mode":"fallback","repo":"%s"}\n' \
		"$token_file" "$expires_at" "$repo_slug"
	return 0
}

# Write a token to a secure temporary file.
# Args: $1 = token, $2 = repo_slug, $3 = expires_at, $4 = mode
# Outputs: token file path on stdout
write_token_file() {
	local token="$1"
	local repo_slug="$2"
	local expires_at="$3"
	local mode="$4"

	# Create a unique token file
	local sanitized_repo
	sanitized_repo=$(printf '%s' "$repo_slug" | tr '/' '-')
	local timestamp
	timestamp=$(date +%s)
	local token_file="${TOKEN_DIR}/${sanitized_repo}-${timestamp}-$$.token"

	# Write token with metadata header (token on last line for easy extraction)
	{
		echo "# gh-token-helper.sh managed token"
		echo "# repo: ${repo_slug}"
		echo "# mode: ${mode}"
		echo "# created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
		echo "# expires: ${expires_at}"
		echo "# DO NOT commit this file"
		echo "${token}"
	} >"$token_file"

	chmod 600 "$token_file"

	printf '%s' "$token_file"
	return 0
}

# =============================================================================
# Token extraction (for consumers)
# =============================================================================

# Extract the token value from a token file.
# Args: $1 = token_file_path
# Outputs: raw token string on stdout
# NOTE: This function outputs a secret value. It should ONLY be called
# by dispatch scripts that pipe the value into an environment variable.
# NEVER call this in a context where stdout is logged.
extract_token() {
	local token_file="$1"

	if [[ ! -f "$token_file" ]]; then
		log_error "Token file not found: $token_file"
		return 1
	fi

	# Token is the last non-empty line (after metadata comments)
	tail -1 "$token_file"
	return 0
}

# =============================================================================
# Token revocation / cleanup
# =============================================================================

# Revoke/clean up a token file.
# For App tokens, the token auto-expires (1h TTL enforced by GitHub).
# For fallback tokens, we just delete the file (token itself can't be revoked).
# Args: --token-file <path>
cmd_revoke() {
	local token_file=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--token-file | -f)
			token_file="$2"
			shift 2
			;;
		*)
			shift
			;;
		esac
	done

	if [[ -z "$token_file" ]]; then
		log_error "Usage: gh-token-helper.sh revoke --token-file <path>"
		return 1
	fi

	if [[ ! -f "$token_file" ]]; then
		log_warn "Token file already removed: $token_file"
		return 0
	fi

	# Check if this is an App token (could revoke via API, but 1h TTL
	# makes this unnecessary — just delete the file)
	local mode
	mode=$(grep '^# mode:' "$token_file" 2>/dev/null | sed 's/^# mode: //' || echo "unknown")

	# Securely delete: overwrite with zeros before unlinking
	local file_size
	file_size=$(wc -c <"$token_file" 2>/dev/null | tr -d ' ')
	if [[ -n "$file_size" && "$file_size" -gt 0 ]]; then
		dd if=/dev/zero of="$token_file" bs=1 count="$file_size" conv=notrunc 2>/dev/null || true
	fi
	rm -f "$token_file"

	log_success "Revoked token file ($mode mode)"
	return 0
}

# Clean up all expired token files.
cmd_cleanup() {
	if [[ ! -d "$TOKEN_DIR" ]]; then
		log_info "No token directory found"
		return 0
	fi

	local cleaned=0
	local now_epoch
	now_epoch=$(date +%s)

	for token_file in "${TOKEN_DIR}"/*.token; do
		[[ -f "$token_file" ]] || continue

		# Extract expiry from metadata
		local expires_line
		expires_line=$(grep '^# expires:' "$token_file" 2>/dev/null || echo "")
		if [[ -z "$expires_line" ]]; then
			continue
		fi

		local expires_at
		expires_at=$(echo "$expires_line" | sed 's/^# expires: //')
		if [[ "$expires_at" == "unknown" ]]; then
			# Fallback tokens older than TTL — clean up
			local created_line
			created_line=$(grep '^# created:' "$token_file" 2>/dev/null || echo "")
			if [[ -n "$created_line" ]]; then
				local created_at
				created_at=$(echo "$created_line" | sed 's/^# created: //')
				local created_epoch
				created_epoch=$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$created_at" '+%s' 2>/dev/null ||
					date -u -d "$created_at" '+%s' 2>/dev/null ||
					echo 0)
				local age=$((now_epoch - created_epoch))
				if [[ "$age" -gt $((DEFAULT_TTL_MINUTES * 60)) ]]; then
					cmd_revoke --token-file "$token_file"
					((cleaned++))
				fi
			fi
			continue
		fi

		# Parse expiry timestamp
		local expires_epoch
		expires_epoch=$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$expires_at" '+%s' 2>/dev/null ||
			date -u -d "$expires_at" '+%s' 2>/dev/null ||
			echo 0)

		if [[ "$now_epoch" -gt "$expires_epoch" ]]; then
			cmd_revoke --token-file "$token_file"
			((cleaned++))
		fi
	done

	if [[ "$cleaned" -gt 0 ]]; then
		log_success "Cleaned up $cleaned expired token file(s)"
	else
		log_info "No expired tokens found"
	fi
	return 0
}

# =============================================================================
# Status
# =============================================================================

cmd_status() {
	echo ""
	log_info "GitHub Token Helper Status"
	echo "================================"
	echo ""

	# Check GitHub App configuration
	if load_app_config; then
		echo -e "  GitHub App:     ${GREEN}configured${NC}"
		echo -e "  App ID:         ${_GH_APP_ID}"
		echo -e "  Key file:       ${_GH_APP_KEY_PATH}"
		if [[ -n "$_GH_APP_INSTALL_ID" ]]; then
			echo -e "  Installation:   ${_GH_APP_INSTALL_ID}"
		else
			echo -e "  Installation:   ${YELLOW}auto-detect${NC}"
		fi
		echo -e "  Token mode:     ${GREEN}app (enforced scoping)${NC}"
	else
		echo -e "  GitHub App:     ${YELLOW}not configured${NC}"
		echo -e "  Token mode:     ${YELLOW}fallback (advisory scoping)${NC}"
		echo -e "  Setup:          Run ${CYAN}gh-token-helper.sh setup${NC}"
	fi

	echo ""

	# Check active tokens
	if [[ -d "$TOKEN_DIR" ]]; then
		local active_count=0
		local expired_count=0
		local now_epoch
		now_epoch=$(date +%s)

		for token_file in "${TOKEN_DIR}"/*.token; do
			[[ -f "$token_file" ]] || continue

			local expires_line
			expires_line=$(grep '^# expires:' "$token_file" 2>/dev/null || echo "")
			local expires_at
			expires_at=$(echo "$expires_line" | sed 's/^# expires: //')

			local expires_epoch
			expires_epoch=$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$expires_at" '+%s' 2>/dev/null ||
				date -u -d "$expires_at" '+%s' 2>/dev/null ||
				echo 0)

			if [[ "$now_epoch" -gt "$expires_epoch" ]]; then
				((expired_count++))
			else
				((active_count++))
			fi
		done

		echo -e "  Active tokens:  ${active_count}"
		if [[ "$expired_count" -gt 0 ]]; then
			echo -e "  Expired tokens: ${YELLOW}${expired_count}${NC} (run 'gh-token-helper.sh cleanup')"
		fi
	else
		echo -e "  Active tokens:  0"
	fi

	# Check gh CLI auth
	echo ""
	if gh auth status &>/dev/null; then
		echo -e "  gh CLI auth:    ${GREEN}authenticated${NC}"
	else
		echo -e "  gh CLI auth:    ${RED}not authenticated${NC}"
	fi

	echo ""
	return 0
}

# =============================================================================
# Setup guide
# =============================================================================

cmd_setup() {
	echo ""
	log_info "GitHub App Setup for Scoped Worker Tokens"
	echo "================================================"
	echo ""
	echo "A GitHub App provides enforced, repo-scoped tokens with 1-hour TTL."
	echo "Without it, workers use your personal token (less secure)."
	echo ""
	echo "Step 1: Create a GitHub App"
	echo "  1. Go to: https://github.com/settings/apps/new"
	echo "  2. Name: 'aidevops-worker-tokens' (or similar)"
	echo "  3. Homepage URL: https://aidevops.sh"
	echo "  4. Uncheck 'Webhook > Active' (not needed)"
	echo "  5. Permissions (Repository):"
	echo "     - Contents: Read & write"
	echo "     - Pull requests: Read & write"
	echo "     - Issues: Read & write"
	echo "     - Metadata: Read-only (auto-granted)"
	echo "  6. Where can this app be installed: 'Only on this account'"
	echo "  7. Click 'Create GitHub App'"
	echo ""
	echo "Step 2: Generate a private key"
	echo "  1. On the App settings page, scroll to 'Private keys'"
	echo "  2. Click 'Generate a private key'"
	echo "  3. Save the .pem file to a secure location"
	echo "  4. Set permissions: chmod 600 /path/to/key.pem"
	echo ""
	echo "Step 3: Install the App"
	echo "  1. Go to: https://github.com/settings/apps/<app-name>/installations"
	echo "  2. Click 'Install' on your account/org"
	echo "  3. Select 'All repositories' or specific repos"
	echo ""
	echo "Step 4: Configure aidevops"
	echo ""
	echo "  Option A: Environment variables (recommended for CI)"
	echo "    export AIDEVOPS_GH_APP_ID='<app-id-from-step-1>'"
	echo "    export AIDEVOPS_GH_APP_PRIVATE_KEY='/path/to/key.pem'"
	echo ""
	echo "  Option B: Config file"
	echo "    mkdir -p ${CONFIG_DIR}"
	echo "    cat > ${GH_APP_CONFIG_FILE} << 'EOF'"
	echo '    {'
	echo '      "app_id": "<app-id>",'
	echo '      "private_key_path": "/path/to/key.pem"'
	echo '    }'
	echo "    EOF"
	echo "    chmod 600 ${GH_APP_CONFIG_FILE}"
	echo ""
	echo "Step 5: Verify"
	echo "  gh-token-helper.sh status"
	echo ""
	echo "After setup, worker dispatch will automatically use scoped tokens."
	echo ""
	return 0
}

# =============================================================================
# Help
# =============================================================================

cmd_help() {
	echo ""
	log_info "gh-token-helper.sh - Scoped GitHub tokens for worker agents (t1412.2)"
	echo ""
	echo "Commands:"
	echo "  create   --repo <owner/repo>   Create a scoped token for a repo"
	echo "           [--permissions <json>] Custom permissions (default: contents+PRs+issues write)"
	echo "           [--ttl <minutes>]      Advisory TTL for fallback mode (default: 60)"
	echo ""
	echo "  revoke   --token-file <path>    Revoke/delete a token file"
	echo "  cleanup                         Remove all expired token files"
	echo "  status                          Show configuration and active tokens"
	echo "  setup                           Interactive GitHub App setup guide"
	echo "  help                            Show this help"
	echo ""
	echo "Modes:"
	echo "  app      GitHub App installation token (preferred)"
	echo "           - Enforced repo scoping by GitHub"
	echo "           - 1-hour TTL (non-configurable, enforced by GitHub)"
	echo "           - Requires one-time GitHub App setup"
	echo ""
	echo "  fallback User's existing gh auth token"
	echo "           - NOT scoped (full access to all repos)"
	echo "           - Advisory TTL only (token doesn't actually expire)"
	echo "           - Zero configuration required"
	echo ""
	echo "Integration with dispatch:"
	echo "  # In dispatch wrapper script:"
	echo "  TOKEN_JSON=\$(gh-token-helper.sh create --repo owner/repo)"
	echo "  TOKEN_FILE=\$(echo \"\$TOKEN_JSON\" | jq -r '.token_file')"
	echo "  export GH_TOKEN_FILE=\"\$TOKEN_FILE\""
	echo "  # ... run worker ..."
	echo "  gh-token-helper.sh revoke --token-file \"\$TOKEN_FILE\""
	echo ""
	echo "Environment variables:"
	echo "  AIDEVOPS_GH_APP_ID            GitHub App ID"
	echo "  AIDEVOPS_GH_APP_PRIVATE_KEY   Path to App private key (.pem)"
	echo "  AIDEVOPS_GH_APP_INSTALL_ID    Installation ID (auto-detected if unset)"
	echo ""
	return 0
}

# =============================================================================
# Main dispatch
# =============================================================================

main() {
	local command="${1:-help}"
	shift 2>/dev/null || true

	case "$command" in
	create) cmd_create "$@" ;;
	revoke) cmd_revoke "$@" ;;
	cleanup) cmd_cleanup "$@" ;;
	status) cmd_status "$@" ;;
	setup) cmd_setup "$@" ;;
	help | --help | -h) cmd_help ;;
	*)
		log_error "Unknown command: $command"
		cmd_help
		return 1
		;;
	esac

	return 0
}

main "$@"
