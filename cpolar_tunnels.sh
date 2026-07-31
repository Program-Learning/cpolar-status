#!/usr/bin/env bash
#
# cpolar_tunnels.sh - 获取 cpolar 隧道信息
#
# 用法:
#   ./cpolar_tunnels.sh [选项]
#
# 选项:
#   --username <用户名>   登录用户名（必填）
#   --password <密码>     登录密码（必填）
#   --baseurl <基址>      面板地址（可选，默认 http://127.0.0.1:9200）
#   --filter <名称>       只显示指定隧道（如 ssh）
#   --json                输出原始 JSON
#   -h, --help            显示本帮助
#
# 示例:
#   ./cpolar_tunnels.sh --username user@example.com --password xxxx
#   ./cpolar_tunnels.sh --username user@example.com --password xxxx --filter ssh
#   ./cpolar_tunnels.sh --username user@example.com --password xxxx --filter ssh --json
#   ./cpolar_tunnels.sh --username user@example.com --password xxxx --json
#
set -euo pipefail

# ===================== 配置区 =====================
CPOLAR_BASEURL="http://127.0.0.1:9200"
# ===================================================

usage() {
  sed -n '2,21p' "$0"
}

username=""
password=""
baseurl=""
filter=""
json_output=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --username)
      [[ $# -ge 2 ]] || { echo "错误: --username 需要一个参数" >&2; exit 1; }
      username="$2"; shift 2
      ;;
    --password)
      [[ $# -ge 2 ]] || { echo "错误: --password 需要一个参数" >&2; exit 1; }
      password="$2"; shift 2
      ;;
    --baseurl)
      [[ $# -ge 2 ]] || { echo "错误: --baseurl 需要一个参数" >&2; exit 1; }
      baseurl="$2"; shift 2
      ;;
    --filter)
      [[ $# -ge 2 ]] || { echo "错误: --filter 需要一个参数" >&2; exit 1; }
      filter="$2"; shift 2
      ;;
    --json)
      json_output=1; shift
      ;;
    -h|--help)
      usage; exit 0
      ;;
    *)
      echo "错误: 未知参数 $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

baseurl="${baseurl:-$CPOLAR_BASEURL}"

if [[ -z "$username" || -z "$password" ]]; then
  echo "错误: --username 和 --password 为必填参数" >&2
  usage >&2
  exit 1
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
  token=$(_login) || {
    echo "错误: 登录失败，请检查用户名和密码" >&2
    exit 1
  }
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
