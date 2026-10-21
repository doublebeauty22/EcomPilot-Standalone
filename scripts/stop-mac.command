#!/bin/bash
set -euo pipefail
export PATH="/Applications/Docker.app/Contents/Resources/bin:$HOME/.docker/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
if [[ ! -f .env.local ]]; then
  printf '尚未创建本机体验环境，无需停止。\n'
  exit 0
fi
docker compose --project-name ecompilot-local --env-file "$ROOT/.env.local" -f "$ROOT/compose.local.yml" stop
printf '已停止 EcomPilot。数据库和体验记录已保留，重新运行 start-mac.command 即可恢复。\n'
