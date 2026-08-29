#!/usr/bin/env bash
# Move legacy Docker config "auth" values into the macOS Keychain helper.
# The config file is changed only after every credential has been validated and
# stored successfully. Re-running this script after success is a no-op.

set -euo pipefail

config_file=${DOCKER_CONFIG_FILE:-"${HOME}/.docker/config.json"}

if [[ ! -e "$config_file" ]]; then
	exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
	echo "Cannot migrate Docker credentials: jq is required." >&2
	exit 1
fi

if ! jq -e 'type == "object"' "$config_file" >/dev/null 2>&1; then
	echo "Cannot migrate Docker credentials: config is not a valid JSON object." >&2
	exit 1
fi

if ! jq -e '
  (.auths // {}) as $auths |
  ($auths | type) == "object" and
  all($auths | to_entries[];
    (.key | length) > 0 and
    ((.value | type) != "object" or
      (.value | has("auth") | not) or
      (.value.auth | type) == "string"))
' "$config_file" >/dev/null 2>&1; then
	echo "Cannot migrate Docker credentials: an inline auth entry is malformed." >&2
	exit 1
fi

auth_count=$(jq '[.auths // {} | to_entries[] | select(.value | type == "object" and has("auth"))] | length' "$config_file")
if [[ "$auth_count" -eq 0 ]]; then
	chmod 600 "$config_file"
	exit 0
fi

credential_helper=${DOCKER_CREDENTIAL_HELPER:-}
if [[ -z "$credential_helper" ]]; then
	credential_helper=$(command -v docker-credential-osxkeychain || true)
fi
if [[ -z "$credential_helper" || ! -x "$credential_helper" ]]; then
	echo "Cannot migrate Docker credentials: docker-credential-osxkeychain is required." >&2
	exit 1
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/docker-credential-migration.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT
chmod 700 "$work_dir"

# Validate and prepare every credential before writing anything to Keychain.
for ((index = 0; index < auth_count; index++)); do
	entry_file="$work_dir/entry.$index.json"
	decoded_file="$work_dir/decoded.$index"
	credential_file="$work_dir/credential.$index.json"
	umask 077

	jq --argjson index "$index" '
    [.auths // {} | to_entries[] | select(.value | type == "object" and has("auth"))][$index]
  ' "$config_file" > "$entry_file"

	if ! jq -r '.value.auth' "$entry_file" | /usr/bin/base64 -D > "$decoded_file" 2>/dev/null; then
		echo "Cannot migrate Docker credentials: an inline auth value is not valid Base64." >&2
		exit 1
	fi

	if ! jq -Rs --arg server_url "$(jq -r '.key' "$entry_file")" '
    index(":") as $separator |
    if $separator == null or $separator == 0 or $separator == (length - 1) then
      error("expected nonempty username:secret")
    else
      {
        ServerURL: $server_url,
        Username: .[0:$separator],
        Secret: .[$separator + 1:]
      }
    end
  ' "$decoded_file" > "$credential_file" 2>/dev/null; then
		echo "Cannot migrate Docker credentials: decoded auth is not username:secret." >&2
		exit 1
	fi
done

# The helper's output is suppressed because an unexpected implementation must
# never echo credential material. A failed store leaves the config untouched.
for credential_file in "$work_dir"/credential.*.json; do
	if ! "$credential_helper" store < "$credential_file" >/dev/null 2>"$work_dir/helper-error"; then
		echo "Cannot migrate Docker credentials: Keychain storage failed; Docker config was not changed." >&2
		exit 1
	fi
done

updated_file="$work_dir/config.json"
jq '
  .auths |= with_entries(
    if (.value | type) == "object" then
      .value |= del(.auth)
    else
      .
    end
  )
' "$config_file" > "$updated_file"
chmod 600 "$updated_file"
mv "$updated_file" "$config_file"
