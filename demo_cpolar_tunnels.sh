#!/usr/bin/env bash
#
# demo_cpolar_tunnels.sh - 展示 cpolar_tunnels.sh 各指令及执行结果
#
# 运行（用户名/密码通过环境变量传入，不写入脚本）:
#   CPOLAR_USERNAME=xxx CPOLAR_PASSWORD=xxx ./demo_cpolar_tunnels.sh
#
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/cpolar_tunnels.sh"

if [[ -z "${CPOLAR_USERNAME:-}" || -z "${CPOLAR_PASSWORD:-}" ]]; then
  echo "错误: 需要设置环境变量 CPOLAR_USERNAME 和 CPOLAR_PASSWORD" >&2
  exit 1
fi
CREDS=(--username "$CPOLAR_USERNAME" --password "$CPOLAR_PASSWORD")

run() { # 指令描述, 参数...
  local desc="$1"; shift
  local args=("$@")
  echo "────────────────────────────────────────────────────────"
  echo "# $desc"
  echo "\$ $SCRIPT ${args[*]}"
  echo "────────────────────────────────────────────────────────"
  "$SCRIPT" "${args[@]}"
  echo "exit=$?"
  echo
}

run "默认，获取全部隧道" "${CREDS[@]}"
run "只显示 ssh 隧道" "${CREDS[@]}" --filter ssh
run "只显示 ssh 隧道(JSON)" "${CREDS[@]}" --filter ssh --json
run "获取全部隧道(JSON)" "${CREDS[@]}" --json
run "参数顺序交换" "${CREDS[@]}" --json --filter admin
run "过滤不存在的隧道" "${CREDS[@]}" --filter no_such_tunnel
run "显式传入面板基址" "${CREDS[@]}" --baseurl http://127.0.0.1:9200 --filter vnc
run "错误的面板基址" "${CREDS[@]}" --baseurl http://127.0.0.1:1
run "查看帮助" --help
run "未知参数" --badarg
run "--filter 缺参数" "${CREDS[@]}" --filter
run "缺少用户名密码" 
