# cpolar-status

> **[中文文档](README_cn.md) · [English](README.md)**

Query and display your [cpolar](https://www.cpolar.com) tunnel status from the local cpolar dashboard API.

## Features

- Logs into the local cpolar dashboard and lists all tunnels
- Shows each tunnel as `name  public_url → 127.0.0.1:localport`
- Filter tunnels by name (`--filter`)
- Output raw JSON (`--json`)
- Chinese / English localized output via gettext
- Packaged as a Nix flake

## Requirements

- bash
- curl
- jq
- gettext

## Usage

```
cpolar-status --username <user> --password <pass> [options]
```

Options:

| Option              | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| `--username <user>` | login username (required)                                    |
| `--password <pass>` | login password (required)                                    |
| `--baseurl <url>`   | dashboard base URL (optional, default `http://127.0.0.1:9200`) |
| `--filter <name>`   | only show the named tunnel (e.g. `ssh`)                       |
| `--json`            | output raw JSON                                               |
| `-h, --help`        | show help                                                     |

Examples:

```sh
cpolar-status --username user@example.com --password xxxx
cpolar-status --username user@example.com --password xxxx --filter ssh
cpolar-status --username user@example.com --password xxxx --filter ssh --json
cpolar-status --username user@example.com --password xxxx --json
```

Sample text output:

```
ssh    https://xxxxx.r2.cpolar.cn   → 127.0.0.1:22
admin  https://xxxxx.r2.cpolar.cn   → 127.0.0.1:8080
```

## Run without installing

```sh
./cpolar-status.sh --username user@example.com --password xxxx
```

## Nix

Build and install the flake package:

```sh
nix build
nix profile install .  # or: nix profile install .#default
```

Enter the development shell (contains `jq`, `curl`, `gettext`):

```sh
nix develop
```

## Testing

Run the test suite with real credentials passed via environment variables
(they are never written into any file):

```sh
CPOLAR_USERNAME=user@example.com CPOLAR_PASSWORD=xxxx ./test_cpolar-status.sh
```

A demo script that walks through every option is also provided:

```sh
CPOLAR_USERNAME=user@example.com CPOLAR_PASSWORD=xxxx ./demo_cpolar-status.sh
```

Both scripts require `gettext`/`msgfmt` and a `zh_CN.UTF-8` locale (as
provided by `nix develop`).

## Localization

Translations live in `po/` and are compiled with `msgfmt`. The language is
chosen from `LANG`/`LC_ALL`/`LC_MESSAGES`; English is the fallback when no
catalog matches.

- `po/cpolar-status.pot` — translation template
- `po/zh_CN.po` — Simplified Chinese catalog

## License

MIT
