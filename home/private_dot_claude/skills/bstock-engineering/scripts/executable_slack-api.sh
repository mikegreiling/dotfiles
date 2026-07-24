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
#   slack-api.sh msg-delete [--force] <channel_id> <message_ts>
#   slack-api.sh msg-edit [--force] <channel_id> <message_ts> <new_text>
#   slack-api.sh open-conversation <user_id[,user_id,...]>   (create-if-not-exists; prints channel id)
#   slack-api.sh mark-read <channel_id> [<message_ts>]   (omit ts = mark all read)
#   slack-api.sh permalink <channel_id> <message_ts>   (canonical share link, same as GUI "Copy link")
#   slack-api.sh preview-strip [--force] <channel_id> <message_ts>   (remove a link-preview card)
#   slack-api.sh react-add <channel_id> <message_ts> <emoji_name>
#   slack-api.sh react-remove <channel_id> <message_ts> <emoji_name>
#
# Notes:
#   - mark-read works on DMs/group-DMs/private channels only. On PUBLIC channels
#     it fails (channels:write not granted) and prints a message telling Mike to
#     mark that one read himself.
#   - <channel_id> may be a user_id (e.g. U065SDTU138) for a DM.
#   - <emoji_name> has NO colons (e.g. white_check_mark, eyes, thankyou).
#   - msg-delete has an AUTHORSHIP GUARD: it refuses to delete a message unless
#     that message was sent via Claude (Slack app_id A08SF47R6P4). A message typed
#     by Mike in the Slack client has no app_id and is REFUSED. Pass --force to
#     override deliberately. This is a guard-rail, not a security boundary — a
#     determined agent could call chat.delete directly; the point is to make the
#     frictionless, skill-blessed path the safe one.
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

# Authorship lookup for the msg-delete/msg-edit guard. conversations.history never
# returns THREAD REPLIES, so on a miss we fall back to conversations.replies, which
# accepts a reply's own ts. Prints: CLAUDE | OTHER … | NOTFOUND | ERR …
_lookup_verdict() { # channel  ts
  local ch=$1 ts=$2 out
  out=$(_api conversations.history "{\"channel\":\"$ch\",\"oldest\":\"$ts\",\"inclusive\":true,\"limit\":1}" | python3 -c "
import sys,json
CLAUDE_APP='A08SF47R6P4'  # the Claude Slack app id (stable); see slack-workflow.md
d=json.load(sys.stdin)
if not d.get('ok'): print('ERR '+str(d.get('error'))); sys.exit()
ms=d.get('messages',[])
if not ms or ms[0].get('ts')!='$ts': print('MISS'); sys.exit()
m=ms[0]
print('CLAUDE' if m.get('app_id')==CLAUDE_APP else 'OTHER app_id=%r user=%r'%(m.get('app_id'),m.get('user')))
")
  if [ "$out" = "MISS" ]; then
    # NB: conversations.replies rejects JSON POST bodies (invalid_arguments) — must be GET.
    out=$(curl -s -H "Authorization: Bearer $(_token)" "https://slack.com/api/conversations.replies?channel=$ch&ts=$ts&limit=50" | python3 -c "
import sys,json
CLAUDE_APP='A08SF47R6P4'
d=json.load(sys.stdin)
if not d.get('ok'): print('NOTFOUND'); sys.exit()  # thread_not_found etc. = message doesn't exist
m=next((x for x in d.get('messages',[]) if x.get('ts')=='$ts'),None)
if m is None: print('NOTFOUND'); sys.exit()
print('CLAUDE' if m.get('app_id')==CLAUDE_APP else 'OTHER app_id=%r user=%r'%(m.get('app_id'),m.get('user')))
")
  fi
  printf '%s' "$out"
}

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
    force=0
    if [ "${1:-}" = "--force" ]; then force=1; shift; fi
    [ $# -eq 2 ] || die "usage: msg-delete [--force] <channel_id|user_id> <message_ts>"
    ch=$(_resolve "$1")
    # AUTHORSHIP GUARD: only delete messages sent via Claude (app_id CLAUDE_APP_ID)
    # unless --force. A client-typed message has no app_id; a Claude/MCP send carries it.
    verdict=$(_lookup_verdict "$ch" "$2")
    case "$verdict" in
      CLAUDE) : ;;
      NOTFOUND) die "message $2 not found in $ch (already deleted, or wrong ts)" ;;
      ERR*) die "could not verify authorship: ${verdict#ERR }" ;;
      OTHER*)
        if [ $force -eq 1 ]; then
          echo "  (--force: overriding authorship guard — $verdict)" >&2
        else
          die "REFUSED: message $2 was NOT sent via Claude ($verdict). This guard only deletes Claude-authored messages. Re-run with --force to override."
        fi ;;
    esac
    _api chat.delete "{\"channel\":\"$ch\",\"ts\":\"$2\"}" | python3 -c "import sys,json;d=json.load(sys.stdin);print('ok' if d.get('ok') else 'ERR '+str(d.get('error')))" ;;

  msg-edit)
    force=0
    if [ "${1:-}" = "--force" ]; then force=1; shift; fi
    [ $# -eq 3 ] || die "usage: msg-edit [--force] <channel_id|user_id> <message_ts> <new_text>"
    ch=$(_resolve "$1")
    # Same AUTHORSHIP GUARD as msg-delete: only edit Claude-authored messages unless --force.
    verdict=$(_lookup_verdict "$ch" "$2")
    case "$verdict" in
      CLAUDE) : ;;
      NOTFOUND) die "message $2 not found in $ch (already deleted, or wrong ts)" ;;
      ERR*) die "could not verify authorship: ${verdict#ERR }" ;;
      OTHER*)
        if [ $force -eq 1 ]; then echo "  (--force: overriding authorship guard — $verdict)" >&2
        else die "REFUSED: message $2 was NOT sent via Claude ($verdict). This guard only edits Claude-authored messages. Re-run with --force to override."; fi ;;
    esac
    printf '%s' "$3" | python3 -c "import sys,json;print(json.dumps({'channel':'$ch','ts':'$2','text':sys.stdin.read()}))" > /tmp/.slack_edit.json
    _api chat.update "$(cat /tmp/.slack_edit.json)" | python3 -c "import sys,json;d=json.load(sys.stdin);print('ok' if d.get('ok') else 'ERR '+str(d.get('error')))"
    rm -f /tmp/.slack_edit.json ;;

  open-conversation)
    # "mkdir -p" for a conversation: open (creating if it doesn't exist) a DM (1 user)
    # or group DM / MPIM (2+ users), and print the channel id on stdout. Idempotent —
    # the same member set always resolves to the same channel id.
    # NOTE: this MATERIALIZES the conversation server-side and opens it in Mike's own
    # sidebar. Other members very likely do NOT see it until the first message is sent
    # (documented Slack behavior — NOT API-verified; see slack-workflow.md). Drafts
    # themselves can't be created here (internal client API) — after this, Claude calls
    # the slack_send_message_draft MCP tool with the printed channel id.
    [ $# -eq 1 ] || die "usage: open-conversation <user_id[,user_id,...]>   (comma-separated, NO spaces)"
    _api conversations.open "{\"users\":\"$1\"}" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if not d.get('ok'): sys.exit('open failed: '+str(d.get('error')))
c=d['channel']
print(c['id'])
sys.stderr.write('  opened '+c['id']+' (name='+repr(c.get('name'))+', already_open='+str(d.get('already_open'))+', no_op='+str(d.get('no_op'))+')\n')
sys.stderr.write('  materialized in Mike\'s sidebar; likely hidden to other members until first message (UNVERIFIED)\n')
" ;;

  mark-read)
    [ $# -ge 1 ] && [ $# -le 2 ] || die "usage: mark-read <channel_id|user_id> [<message_ts>]"
    ch=$(_resolve "$1")
    ts="${2:-}"
    if [ -z "$ts" ]; then  # default: mark everything read (up to the latest message)
      ts=$(_api conversations.history "{\"channel\":\"$ch\",\"limit\":1}" | python3 -c "import sys,json;d=json.load(sys.stdin);ms=d.get('messages',[]);print(ms[0]['ts'] if ms else '')")
      [ -n "$ts" ] || die "could not read latest message in $ch (empty channel, or no history access)"
    fi
    _api conversations.mark "{\"channel\":\"$ch\",\"ts\":\"$ts\"}" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if d.get('ok'):
    print('  ok — marked read up to $ts')
elif d.get('error')=='missing_scope':
    print('  CANNOT mark read — this is almost certainly a PUBLIC channel; the Claude app lacks channels:write.')
    print('  Mark this one read yourself in the Slack client. (Private channels, DMs, and group DMs work; public channels do not.)')
else:
    print('  ERR '+str(d.get('error'))+' (e.g. not_in_channel = Claude is not a member)')
" ;;

  permalink)
    # Canonical permalink for a message — byte-identical to the GUI "Copy link".
    # Top-level: https://<ws>.slack.com/archives/<CH>/p<ts-without-dot>
    # Thread replies automatically gain ?thread_ts=<parent>&cid=<ch>.
    [ $# -eq 2 ] || die "usage: permalink <channel_id|user_id> <message_ts>"
    ch=$(_resolve "$1")
    curl -s -H "Authorization: Bearer $(_token)" "https://slack.com/api/chat.getPermalink?channel=$ch&message_ts=$2" \
      | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['permalink']) if d.get('ok') else sys.exit('ERR '+str(d.get('error')))" ;;

  preview-strip)
    # Remove a link-preview (unfurl) card from a sent message — the API equivalent of
    # the GUI's "x" on a preview. chat.update with the message's own text + empty
    # attachments strips the card and leaves the text untouched (verified 2026-07-23).
    # AUTHORSHIP-GUARDED like msg-edit: for Mike's own hand-typed messages the GUI "x"
    # is the right tool; --force overrides deliberately.
    force=0
    if [ "${1:-}" = "--force" ]; then force=1; shift; fi
    [ $# -eq 2 ] || die "usage: preview-strip [--force] <channel_id|user_id> <message_ts>"
    ch=$(_resolve "$1")
    _api conversations.history "{\"channel\":\"$ch\",\"oldest\":\"$2\",\"inclusive\":true,\"limit\":1}" | python3 -c "
import sys,json
CLAUDE_APP='A08SF47R6P4'
d=json.load(sys.stdin)
if not d.get('ok'): sys.exit('ERR '+str(d.get('error')))
ms=d.get('messages',[])
if not ms or ms[0].get('ts')!='$2': sys.exit('NOTFOUND: message $2 not in $ch (already deleted, or wrong ts)')
m=ms[0]
if not m.get('attachments'): sys.exit('NOPREVIEW: message has no preview/attachments to strip')
if m.get('app_id')!=CLAUDE_APP and $force==0:
    sys.exit('REFUSED: message was NOT sent via Claude (app_id=%r). Use the GUI x on the preview, or re-run with --force.'%m.get('app_id'))
json.dump({'channel':'$ch','ts':'$2','text':m.get('text',''),'attachments':[]},open('/tmp/.slack_strip.json','w'))
" || die "preview-strip aborted"
    _api chat.update "$(cat /tmp/.slack_strip.json)" | python3 -c "import sys,json;d=json.load(sys.stdin);print('ok — preview removed' if d.get('ok') else 'ERR '+str(d.get('error')))"
    rm -f /tmp/.slack_strip.json ;;

  react-add)
    [ $# -eq 3 ] || die "usage: react-add <channel_id|user_id> <message_ts> <emoji_name>"
    ch=$(_resolve "$1")
    _api reactions.add "{\"channel\":\"$ch\",\"timestamp\":\"$2\",\"name\":\"$3\"}" | python3 -c "import sys,json;d=json.load(sys.stdin);print('ok' if d.get('ok') else 'ERR '+str(d.get('error')))" ;;

  react-remove)
    [ $# -eq 3 ] || die "usage: react-remove <channel_id|user_id> <message_ts> <emoji_name>"
    ch=$(_resolve "$1")
    _api reactions.remove "{\"channel\":\"$ch\",\"timestamp\":\"$2\",\"name\":\"$3\"}" | python3 -c "import sys,json;d=json.load(sys.stdin);print('ok' if d.get('ok') else 'ERR '+str(d.get('error')))" ;;

  *) die "unknown command '$cmd'. run with no args to see usage in the header, or: whoami | scheduled-list | scheduled-delete | scheduled-reschedule | msg-delete | msg-edit | open-conversation | mark-read | permalink | preview-strip | react-add | react-remove" ;;
esac
