#!/usr/bin/env bash
#
# cpolar-status - fetch cpolar tunnel information
#
# Requires: bash, curl, jq, gettext
#
# Usage:
#   cpolar-status [options]
#
# Options:
#   --username <user>    login username (required)
#   --password <pass>    login password (required)
#   --baseurl <url>      dashboard base URL (optional, default http://127.0.0.1:9200)
#   --filter <name>      only show the named tunnel (e.g. ssh)
#   --json               output raw JSON
#   -h, --help           show this help
#
# i18n: uses gettext with TEXTDOMAIN=cpolar-status. Language is chosen from
# LANG/LC_ALL/LC_MESSAGES; English is the fallback when no catalog matches.
#
set -euo pipefail

# i18n setup ---------------------------------------------------------------
export TEXTDOMAIN="${TEXTDOMAIN:-cpolar-status}"
if [[ -z "${TEXTDOMAINDIR:-}" ]]; then
  local_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/share/locale"
  [[ -d "$local_dir" ]] && export TEXTDOMAINDIR="$local_dir"
fi
_() { gettext -d "$TEXTDOMAIN" "$1"; }

# ===================== config =====================
CPOLAR_BASEURL="http://127.0.0.1:9200"
# ==================================================

usage() {
  printf '%s\n' "$(_ 'Usage: cpolar-status [options]

Options:
  --username <user>    login username (required)
  --password <pass>    login password (required)
  --baseurl <url>      dashboard base URL (optional, default http://127.0.0.1:9200)
  --filter <name>      only show the named tunnel (e.g. ssh)
  --json               output raw JSON
  -h, --help           show this help

Examples:
  cpolar-status --username user@example.com --password xxxx
  cpolar-status --username user@example.com --password xxxx --filter ssh
  cpolar-status --username user@example.com --password xxxx --filter ssh --json
  cpolar-status --username user@example.com --password xxxx --json
')"
}

err() { # fmt, args...
  local fmt="$1"; shift
  printf "$(_ "$fmt")\n" "$@" >&2
  exit 1
}

err_usage() { # fmt, args...
  local fmt="$1"; shift
  printf "$(_ "$fmt")\n" "$@" >&2
  usage >&2
  exit 1
}

username=""
password=""
baseurl=""
filter=""
json_output=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --username)
      [[ $# -ge 2 ]] || err 'error: option --%s requires an argument' 'username'
      username="$2"; shift 2
      ;;
    --password)
      [[ $# -ge 2 ]] || err 'error: option --%s requires an argument' 'password'
      password="$2"; shift 2
      ;;
    --baseurl)
      [[ $# -ge 2 ]] || err 'error: option --%s requires an argument' 'baseurl'
      baseurl="$2"; shift 2
      ;;
    --filter)
      [[ $# -ge 2 ]] || err 'error: option --%s requires an argument' 'filter'
      filter="$2"; shift 2
      ;;
    --json)
      json_output=1; shift
      ;;
    -h|--help)
      usage; exit 0
      ;;
    *)
      err_usage 'error: unknown option: %s' "$1"
      ;;
  esac
done

baseurl="${baseurl:-$CPOLAR_BASEURL}"

if [[ -z "$username" || -z "$password" ]]; then
  err_usage 'error: --username and --password are required'
fi

_login() {
  local resp token
  for attempt in 1 2 3 4 5; do
    resp="$(curl -s "$baseurl/api/v1/user/login" \
      -H 'Content-Type: application/json;charset=UTF-8' \
      --data-raw "{\"email\":\"$username\",\"password\":\"$password\"}")"
    if [[ -n "$resp" ]]; then
      token="$(jq -r '.data.token // empty' <<<"$resp" 2>/dev/null)"
      if [[ -n "$token" ]]; then
        printf '%s\n' "$token"
        return 0
      fi
      sleep 2
    else
      return 1
    fi
  done
  return 1
}

_fetch_tunnels() {
  local token
  token=$(_login) || err 'error: login failed, please check username and password'
  curl -s "$baseurl/api/v1/tunnels" \
    -H "Authorization: Bearer $token"
}

json=$(_fetch_tunnels)

if [[ "$json_output" -eq 1 ]]; then
  if [[ -n "$filter" ]]; then
    jq --arg f "$filter" '.data.items |= map(select(.name == $f))' <<<"$json"
  else
    printf '%s\n' "$json"
  fi
else
  if [[ -n "$filter" ]]; then
    jq -r --arg f "$filter" '[.data.items[] |
      select(.name == $f) |
      "\(.name)  \(.public_url)  → 127.0.0.1:\(.configuration.addr)"
    ] | join("\n")' <<<"$json"
  else
    jq -r '[.data.items[] |
      "\(.name)  \(.public_url)  → 127.0.0.1:\(.configuration.addr)"
    ] | join("\n")' <<<"$json"
  fi
fi
