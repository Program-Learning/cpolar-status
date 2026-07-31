# cpolar-status

> **[English](README.md) · [中文文档](README_cn.md)**

查询并展示本地 cpolar 面板 API 中的隧道状态。

## 特性

- 登录本地 cpolar 面板并列出全部隧道
- 每个隧道以 `名称  public_url → 127.0.0.1:本地端口` 形式展示
- 按名称过滤隧道（`--filter`）
- 输出原始 JSON（`--json`）
- 基于 gettext 的中英文双语输出
- 以 Nix flake 打包

## 依赖

- bash
- curl
- jq
- gettext

## 用法

```
cpolar-status --username <用户> --password <密码> [选项]
```

选项:

| 选项                | 说明                                            |
| ------------------- | ----------------------------------------------- |
| `--username <用户>` | 登录用户名（必填）                              |
| `--password <密码>` | 登录密码（必填）                                |
| `--baseurl <基址>`  | 面板地址（可选，默认 `http://127.0.0.1:9200`）  |
| `--filter <名称>`   | 只显示指定隧道（如 `ssh`）                       |
| `--json`            | 输出原始 JSON                                    |
| `-h, --help`        | 显示帮助                                         |

示例:

```sh
cpolar-status --username user@example.com --password xxxx
cpolar-status --username user@example.com --password xxxx --filter ssh
cpolar-status --username user@example.com --password xxxx --filter ssh --json
cpolar-status --username user@example.com --password xxxx --json
```

文本输出示例:

```
ssh    https://xxxxx.r2.cpolar.cn   → 127.0.0.1:22
admin  https://xxxxx.r2.cpolar.cn   → 127.0.0.1:8080
```

## 无需安装直接运行

```sh
./cpolar-status.sh --username user@example.com --password xxxx
```

## Nix

构建并安装 flake 包:

```sh
nix build
nix profile install .  # 或: nix profile install .#default
```

进入开发环境（包含 `jq`、`curl`、`gettext`）:

```sh
nix develop
```

## 测试

通过环境变量传入真实账号密码运行测试（凭据不会写入任何文件）:

```sh
CPOLAR_USERNAME=user@example.com CPOLAR_PASSWORD=xxxx ./test_cpolar-status.sh
```

另提供逐项演示各指令的脚本:

```sh
CPOLAR_USERNAME=user@example.com CPOLAR_PASSWORD=xxxx ./demo_cpolar-status.sh
```

两个脚本都需要 `gettext`/`msgfmt` 及 `zh_CN.UTF-8` locale（在 `nix develop` 环境中均已提供）。

## 本地化

翻译文件位于 `po/`，通过 `msgfmt` 编译。语言根据 `LANG`/`LC_ALL`/`LC_MESSAGES` 选择；找不到对应目录时回退到英文。

- `po/cpolar-status.pot` — 翻译模板
- `po/zh_CN.po` — 简体中文目录

## 许可证

MIT
