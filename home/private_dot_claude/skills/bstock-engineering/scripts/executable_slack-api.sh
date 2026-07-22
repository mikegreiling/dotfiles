#!/usr/bin/env bash
# slack-api.sh — thin helper over the Slack Web API for capabilities the Slack
# MCP server does NOT expose. Uses Mike's Slack plugin OAuth token, read from
# the macOS Keychain at call time (never printed, never cached).
#
# Covers the verified MCP gaps: list/delete/reschedule SCHEDULED messages,
# delete Mike's own messages, add/remove reactions.
#
# CANNOT cover (do not add — no token reaches these):
#   - drafts (list/read/update/delete): Slack INTERNAL client API, not public Web API.
#   - Slack status/presence: users.profile:write scope not granted to this token.
#
# Every write here is a real, visible action — the skill's confirmation rules
# apply exactly as they do to MCP sends/reactions.
#
# Usage:
#   slack-api.sh whoami
#   slack-api.sh scheduled-list <channel_id>
#   slack-api.sh scheduled-delete <channel_id> <scheduled_message_id>
#   slack-api.sh scheduled-reschedule <channel_id> <scheduled_message_id> <new_unix_ts>
#   slack-api.sh msg-delete <channel_id> <message_ts>
#   slack-api.sh react-add <channel_id> <message_ts> <emoji_name>
#   slack-api.sh react-remove <channel_id> <message_ts> <emoji_name>
#
# Notes:
#   - <channel_id> may be a user_id (e.g. U065SDTU138) for a DM.
#   - <emoji_name> has NO colons (e.g. white_check_mark, eyes, thankyou).
#   - scheduled-reschedule is delete+recreate (Slack has no in-place update);
#     it preserves the original text and prints the new id. Safe & verifiable
#     because scheduled messages have stable server IDs and a real list endpoint.

set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

_token() {
  local cred
  cred=$(security find-generic-password -s "Claude Code-credentials" -a "$(whoami)" -w 2>/dev/null) \
    || die "could not read Claude Code credentials from keychain"
  printf '%s' "$cred" | python3 -c "import sys,json;d=json.load(sys.stdin);[print(v['accessToken']) for k,v in d['mcpOAuth'].items() if k.startswith('plugin:slack')]" \
    | head -n1
}

_api() { # method  json-body
  curl -s -H "Authorization: Bearer $(_token)" -H "Content-Type: application/json" -d "$2" "https://slack.com/api/$1"
}

# Raw Web API needs the DM CHANNEL id (D…); the MCP tools accept a user id (U…).
# Resolve a U-prefixed id to its DM channel so callers can use either, like the MCP.
_resolve() {
  case "$1" in
    U*) curl -s -H "Authorization: Bearer $(_token)" -H "Content-Type: application/json" -d "{\"users\":\"$1\"}" "https://slack.com/api/conversations.open" \
          | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['channel']['id']) if d.get('ok') else sys.exit('resolve failed: '+str(d.get('error')))" ;;
    *)  printf '%s' "$1" ;;
  esac
}

_require_ok() { python3 -c "import sys,json;d=json.load(sys.stdin);sys.exit(0 if d.get('ok') else 1) or print(json.dumps(d,indent=2))" ; }

cmd=${1:-}; shift || true
case "$cmd" in
  whoami)
    curl -s -H "Authorization: Bearer $(_token)" "https://slack.com/api/auth.test" | python3 -m json.tool ;;

  scheduled-list)
    [ $# -eq 1 ] || die "usage: scheduled-list <channel_id|user_id>"
    ch=$(_resolve "$1")
    _api chat.scheduledMessages.list "{\"channel\":\"$ch\"}" \
      | python3 -c "import sys,json;d=json.load(sys.stdin);[print(m['id'],m['post_at'],repr(m.get('text','')[:80])) for m in d.get('scheduled_messages',[])] or (print('(none)') if d.get('ok') else print('ERR',d.get('error')))" ;;

  scheduled-delete)
    [ $# -eq 2 ] || die "usage: scheduled-delete <channel_id|user_id> <scheduled_message_id>"
    ch=$(_resolve "$1")
    _api chat.deleteScheduledMessage "{\"channel\":\"$ch\",\"scheduled_message_id\":\"$2\"}" | python3 -c "import sys,json;d=json.load(sys.stdin);print('ok' if d.get('ok') else 'ERR '+str(d.get('error')))" ;;

  scheduled-reschedule)
    [ $# -eq 3 ] || die "usage: scheduled-reschedule <channel_id|user_id> <scheduled_message_id> <new_unix_ts>"
    ch=$(_resolve "$1")
    text=$(_api chat.scheduledMessages.list "{\"channel\":\"$ch\"}" | python3 -c "import sys,json;d=json.load(sys.stdin);print(next((m.get('text','') for m in d.get('scheduled_messages',[]) if m['id']=='$2'),''))")
    [ -n "$text" ] || die "scheduled message $2 not found in channel $ch (already sent or wrong id)"
    _api chat.deleteScheduledMessage "{\"channel\":\"$ch\",\"scheduled_message_id\":\"$2\"}" >/dev/null
    printf '%s' "$text" | python3 -c "import sys,json;t=sys.stdin.read();print(json.dumps({'channel':'$ch','post_at':int('$3'),'text':t}))" > /tmp/.slack_resched.json
    _api chat.scheduleMessage "$(cat /tmp/.slack_resched.json)" | python3 -c "import sys,json;d=json.load(sys.stdin);print('rescheduled -> new id',d.get('scheduled_message_id')) if d.get('ok') else print('ERR',d.get('error'))"
    rm -f /tmp/.slack_resched.json ;;

  msg-delete)
    [ $# -eq 2 ] || die "usage: msg-delete <channel_id|user_id> <message_ts>"
    ch=$(_resolve "$1")
    _api chat.delete "{\"channel\":\"$ch\",\"ts\":\"$2\"}" | python3 -c "import sys,json;d=json.load(sys.stdin);print('ok' if d.get('ok') else 'ERR '+str(d.get('error')))" ;;

  react-add)
    [ $# -eq 3 ] || die "usage: react-add <channel_id|user_id> <message_ts> <emoji_name>"
    ch=$(_resolve "$1")
    _api reactions.add "{\"channel\":\"$ch\",\"timestamp\":\"$2\",\"name\":\"$3\"}" | python3 -c "import sys,json;d=json.load(sys.stdin);print('ok' if d.get('ok') else 'ERR '+str(d.get('error')))" ;;

  react-remove)
    [ $# -eq 3 ] || die "usage: react-remove <channel_id|user_id> <message_ts> <emoji_name>"
    ch=$(_resolve "$1")
    _api reactions.remove "{\"channel\":\"$ch\",\"timestamp\":\"$2\",\"name\":\"$3\"}" | python3 -c "import sys,json;d=json.load(sys.stdin);print('ok' if d.get('ok') else 'ERR '+str(d.get('error')))" ;;

  *) die "unknown command '$cmd'. run with no args to see usage in the header, or: whoami | scheduled-list | scheduled-delete | scheduled-reschedule | msg-delete | react-add | react-remove" ;;
esac
