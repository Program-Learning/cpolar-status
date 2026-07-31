#!/usr/bin/env bash
#
# test_cpolar_tunnels.sh - cpolar_tunnels.sh 的测试用例
#
# 运行（用户名/密码通过环境变量传入，不写入脚本）:
#   CPOLAR_USERNAME=xxx CPOLAR_PASSWORD=xxx ./test_cpolar_tunnels.sh
#
# 依赖 gettext/msgfmt（在 devShell 中运行: nix develop）和 zh_CN locale。
# 测试默认在 zh_CN.UTF-8 下断言中文输出。
#
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/cpolar_tunnels.sh"
REPO="$(cd "$(dirname "$0")" && pwd)"
OUT="$(mktemp)"
PASS=0
FAIL=0

if [[ -z "${CPOLAR_USERNAME:-}" || -z "${CPOLAR_PASSWORD:-}" ]]; then
  echo "错误: 需要设置环境变量 CPOLAR_USERNAME 和 CPOLAR_PASSWORD" >&2
  exit 1
fi
CREDS=(--username "$CPOLAR_USERNAME" --password "$CPOLAR_PASSWORD")

# i18n 准备：用 msgfmt 从 po/ 编译 zh 目录，供脚本的开发环境回退路径使用
for _cmd in gettext msgfmt; do
  command -v "$_cmd" >/dev/null || {
    echo "错误: 需要 $_cmd，请在 devShell 中运行（nix develop）" >&2
    exit 1
  }
done
MO_DIR="$REPO/share/locale/zh_CN/LC_MESSAGES"
mkdir -p "$MO_DIR"
msgfmt -o "$MO_DIR/cpolar-tunnels.mo" "$REPO/po/zh_CN.po"
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

assert_contains() { # 名称, 内容, 期望子串
  if grep -qF "$3" <<<"$2"; then
    echo "  PASS: $1"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $1  (未找到 \"$3\")"
    echo "  -------- 实际输出 --------"
    echo "$2" | sed 's/^/  | /'
    FAIL=$((FAIL + 1))
  fi
}

assert_exit() { # 名称, 期望退出码, 实际退出码
  if [[ "$2" -eq "$3" ]]; then
    echo "  PASS: $1 (exit=$3)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $1 (期望 exit=$2, 实际 exit=$3)"
    FAIL=$((FAIL + 1))
  fi
}

assert_json_valid() { # 名称, json
  if jq -e . >/dev/null 2>&1 <<<"$2"; then
    echo "  PASS: $1 (合法 JSON)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $1 (非法 JSON)"
    echo "$2" | sed 's/^/  | /'
    FAIL=$((FAIL + 1))
  fi
}

echo "===== T01 显式账号密码，应包含全部隧道名 ====="
"$SCRIPT" "${CREDS[@]}" >"$OUT" 2>&1
assert_exit "T01 退出码=0" 0 $?
for n in admin rdp ssh vnc; do
  assert_contains "T01 包含 $n" "$(cat "$OUT")" "$n"
done

echo "===== T02 --json，应为合法 JSON 且 total>0 ====="
"$SCRIPT" "${CREDS[@]}" --json >"$OUT" 2>&1
assert_exit "T02 退出码=0" 0 $?
assert_json_valid "T02 JSON 合法" "$(cat "$OUT")"
total="$(jq -r '.data.total' "$OUT")"
if [[ "$total" =~ ^[1-9][0-9]*$ ]]; then
  echo "  PASS: T02 total=$total"
  PASS=$((PASS + 1))
else
  echo "  FAIL: T02 total 非法 ($total)"
  FAIL=$((FAIL + 1))
fi

echo "===== T03 --filter ssh，应只含 ssh ====="
"$SCRIPT" "${CREDS[@]}" --filter ssh >"$OUT" 2>&1
assert_exit "T03 退出码=0" 0 $?
assert_contains "T03 包含 ssh" "$(cat "$OUT")" "ssh"
out="$(cat "$OUT")"
if grep -q "vnc" <<<"$out"; then
  echo "  FAIL: T03 不应包含 vnc"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: T03 不包含其他隧道"
  PASS=$((PASS + 1))
fi

echo "===== T04 --filter ssh --json，应为 1 条且 name=ssh ====="
"$SCRIPT" "${CREDS[@]}" --filter ssh --json >"$OUT" 2>&1
assert_exit "T04 退出码=0" 0 $?
assert_json_valid "T04 JSON 合法" "$(cat "$OUT")"
count="$(jq '.data.items | length' "$OUT")"
name="$(jq -r '.data.items[0].name' "$OUT")"
if [[ "$count" -eq 1 && "$name" == "ssh" ]]; then
  echo "  PASS: T04 1 条记录 name=ssh"
  PASS=$((PASS + 1))
else
  echo "  FAIL: T04 (count=$count name=$name)"
  FAIL=$((FAIL + 1))
fi

echo "===== T05 --json --filter ssh（参数顺序交换）====="
"$SCRIPT" "${CREDS[@]}" --json --filter ssh >"$OUT" 2>&1
assert_exit "T05 退出码=0" 0 $?
name="$(jq -r '.data.items[0].name' "$OUT" 2>/dev/null)"
if [[ "$name" == "ssh" ]]; then
  echo "  PASS: T05 参数顺序不影响结果"
  PASS=$((PASS + 1))
else
  echo "  FAIL: T05 (name=$name)"
  FAIL=$((FAIL + 1))
fi

echo "===== T06 --filter 不存在的名字，输出为空 ====="
"$SCRIPT" "${CREDS[@]}" --filter no_such_tunnel >"$OUT" 2>&1
assert_exit "T06 退出码=0" 0 $?
if [[ -z "$(cat "$OUT")" ]]; then
  echo "  PASS: T06 输出为空"
  PASS=$((PASS + 1))
else
  echo "  FAIL: T06 应输出为空"
  cat "$OUT" | sed 's/^/  | /'
  FAIL=$((FAIL + 1))
fi

echo "===== T07 --baseurl 错误地址，登录应失败 ====="
"$SCRIPT" "${CREDS[@]}" --baseurl http://127.0.0.1:1 >"$OUT" 2>&1
assert_exit "T07 退出码=1" 1 $?
assert_contains "T07 提示登录失败" "$(cat "$OUT")" "登录失败"

echo "===== T08 --help，应显示用法 ====="
"$SCRIPT" --help >"$OUT" 2>&1
assert_exit "T08 退出码=0" 0 $?
assert_contains "T08 包含用法" "$(cat "$OUT")" "用法"

echo "===== T09 未知参数，应报错退出 1 ====="
"$SCRIPT" --badarg >"$OUT" 2>&1
assert_exit "T09 退出码=1" 1 $?
assert_contains "T09 提示未知参数" "$(cat "$OUT")" "未知参数"

echo "===== T10 --filter 缺参数，应报错退出 1 ====="
"$SCRIPT" "${CREDS[@]}" --filter >"$OUT" 2>&1
assert_exit "T10 退出码=1" 1 $?
assert_contains "T10 提示需要参数" "$(cat "$OUT")" "需要一个参数"

echo "===== T11 缺少用户名/密码，应报错退出 1 ====="
"$SCRIPT" >"$OUT" 2>&1
assert_exit "T11 退出码=1" 1 $?
assert_contains "T11 提示必填" "$(cat "$OUT")" "必填参数"

echo "===== T12 --baseurl 指向面板基址 ====="
"$SCRIPT" "${CREDS[@]}" --baseurl http://127.0.0.1:9200 --filter admin >"$OUT" 2>&1
assert_exit "T12 退出码=0" 0 $?
assert_contains "T12 包含 admin" "$(cat "$OUT")" "admin"

echo "===== T13 默认英文回退（LC_ALL=C），错误应为英文 ====="
env -u LANG LC_ALL=C "$SCRIPT" --badarg >"$OUT" 2>&1
assert_exit "T13 退出码=1" 1 $?
assert_contains "T13 英文错误" "$(cat "$OUT")" "error: unknown option"

echo "===== T14 中文帮助（zh_CN.UTF-8）====="
"$SCRIPT" --help >"$OUT" 2>&1
assert_exit "T14 退出码=0" 0 $?
assert_contains "T14 中文用法" "$(cat "$OUT")" "用法: cpolar-tunnels"

rm -f "$OUT"
echo
echo "=============================="
echo "  通过: $PASS  失败: $FAIL"
echo "=============================="
[[ "$FAIL" -eq 0 ]]
