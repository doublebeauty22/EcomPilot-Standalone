#!/bin/bash
# Local demo launcher; never installs system software or resets existing data.
set -euo pipefail
export PATH="/Applications/Docker.app/Contents/Resources/bin:$HOME/.docker/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { printf '\n%s\n' "$1" >&2; exit 1; }
trap 'printf "\n启动未完成，请保留上面的报错信息。演示数据不会被自动删除。\n" >&2' ERR

command -v docker >/dev/null 2>&1 || fail '请先安装并打开 Docker Desktop（Mac with Apple silicon）：https://docs.docker.com/desktop/setup/install/mac-install/'
docker info >/dev/null 2>&1 || fail 'Docker 引擎尚未运行。请打开 Docker Desktop，等待 Engine running，再运行本文件。'
docker compose version >/dev/null 2>&1 || fail '需要 Docker Compose，请完成 Docker Desktop 安装。'

if [[ ! -e .env.local ]]; then
  umask 077
  DEMO_ACCESS_KEY="$(openssl rand -hex 24)"
  DEMO_DATABASE_PASSWORD="$(openssl rand -hex 24)"
  cat > .env.local <<EOF
# 本机体验配置，已被 Git 忽略。不要提交或分享此文件。
ECOMPILOT_PORT=8002
APP_ENV=development
AUTH_MODE=api_key
ALLOW_INSECURE_LOCAL=false
API_KEY=$DEMO_ACCESS_KEY
PG_PWD=$DEMO_DATABASE_PASSWORD
DEV_TENANT_ID=demo_tenant
DEV_STORE_ID=demo_store
DEV_USER_ID=demo_user
DEV_ROLES=admin
DEMO_STORE_ID=demo_store
DEMO_STORE_NAME=Northstar Outdoor
METRICS_AUTH_REQUIRED=true
RATE_LIMIT_ENABLED=true
LLM_REQUIRED_FOR_READINESS=false
LLM_PROVIDER=deepseek
DEEPSEEK_API_KEY=
OPENAI_API_KEY=
EMBED_MODEL_PATH=
EOF
  unset DEMO_ACCESS_KEY DEMO_DATABASE_PASSWORD
  printf '已生成本机独立的访问密钥和数据库密码。\n'
fi
chmod 600 .env.local

compose() { docker compose --project-name ecompilot-local --env-file "$ROOT/.env.local" -f "$ROOT/compose.local.yml" "$@"; }

printf '\n[1/4] 构建运行环境（首次需要联网下载，可能需要几分钟）\n'
compose build api
printf '\n[2/4] 启动 PostgreSQL 与 Redis\n'
compose up -d --wait --wait-timeout 180 postgres redis

printf '\n[3/4] 检查演示数据\n'
DEMO_MARKER="$(compose exec -T postgres psql -U postgres -d ecom_matrix -tAc "SELECT to_regclass('public.ecompilot_local_demo_setup')")"
if [[ -z "$DEMO_MARKER" ]]; then
  compose run --rm --no-deps api python -m ecom_agent_matrix.scripts.bootstrap_demo
  compose exec -T postgres psql -v ON_ERROR_STOP=1 -U postgres -d ecom_matrix -c 'CREATE TABLE public.ecompilot_local_demo_setup (installed_at timestamptz NOT NULL DEFAULT now()); INSERT INTO public.ecompilot_local_demo_setup DEFAULT VALUES;' >/dev/null
else
  printf '已有演示数据，保留商品修改与体验记录。\n'
fi

printf '\n[4/4] 启动页面并检查数据库连接\n'
compose up -d --wait --wait-timeout 180 api
DEMO_PORT="$(awk -F= '$1 == "ECOMPILOT_PORT" {print $2; exit}' .env.local)"
DEMO_PORT="${DEMO_PORT:-8002}"
DEMO_URL="http://127.0.0.1:${DEMO_PORT}"
curl --fail --silent --show-error --max-time 10 "$DEMO_URL/health/ready"
printf '\n\nEcomPilot 已启动：%s/app\n' "$DEMO_URL"
if command -v pbcopy >/dev/null 2>&1; then
  awk -F= '$1 == "API_KEY" {printf "%s", $2; exit}' .env.local | pbcopy
  printf '访问密钥已复制到剪贴板。请在网页的 API Key 输入框粘贴并保存。\n'
else
  printf '访问密钥位于本机 .env.local 的 API_KEY 字段。\n'
fi
printf '先试：2026年8月销售额是多少？／退款政策是什么？／帮我找防水户外背包。\n'
printf '未配置模型密钥时使用规则与检索回答；自由对话和复杂规划需要另配模型。\n'
printf '关闭终端不会停止服务；停止请运行 scripts/stop-mac.command。\n'
if command -v open >/dev/null 2>&1; then open "$DEMO_URL/app" || true; fi
