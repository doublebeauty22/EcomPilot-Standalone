# 在 Mac 上体验 EcomPilot

## 第一次启动

1. 安装并打开 [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/)。M 系列 Mac 选择 **Mac with Apple silicon**，等待 Docker 引擎运行。
2. 在项目目录运行 `bash scripts/start-mac.command`；也可以在 Finder 中双击该文件。
3. 首次启动需要联网下载镜像和 Python 依赖。脚本会生成本机密钥、启动 PostgreSQL/Redis、导入演示数据，再打开网页。
4. 在网页中选择 API Key 模式，将剪贴板里的访问密钥粘贴到输入框并保存。

默认页面：<http://127.0.0.1:8002/app>。这是本机地址，不能直接发给其他人使用。

## 验收问题

- `2026年8月销售额是多少？`
- `退款政策是什么？`
- `帮我找防水户外背包。`，然后追问 `那库存呢？`
- `哪些商品库存不足，需要优先补货？`

启动脚本使用项目现有的 `bootstrap_demo`，首次导入 52 个商品、720 个订单及知识文档。初始化完成后会在本地数据库记录完成标记；普通重启不会重新导入或覆盖你编辑的商品。如果首次初始化中途失败，下次启动会重试未完成的演示初始化。

## AI 能力说明

默认体验使用确定性路由、SQL 模板和关键词检索，不需要购买模型 API，也不下载大型模型。没有模型密钥时，自由对话、复杂规划和自然语言综合能力受限；关键词检索不等于已启用向量混合检索。

要接入已有模型，在 `.env.local` 中填写 `DEEPSEEK_API_KEY`，或将 `LLM_PROVIDER` 改为 `openai` 并填写 `OPENAI_API_KEY`，然后再次运行启动脚本。密钥只保存在本机，不要发到聊天或提交到 GitHub。

## 停止、重启与排错

- 停止：`bash scripts/stop-mac.command`。保留所有数据。
- 重启：`bash scripts/start-mac.command`。
- 查看日志：`docker compose --project-name ecompilot-local --env-file .env.local -f compose.local.yml logs --tail 80 api`。
- 8002 端口被占用：把 `.env.local` 中的 `ECOMPILOT_PORT` 改为 `8003` 后重启。
- 镜像下载或构建失败：保留报错，检查 Mac 的网络连接后再次运行；脚本不会清空数据库。

`.env.local` 已被 Git 忽略，权限设为仅当前用户可读写。API 仅监听本机，数据库和 Redis 没有映射宿主机端口。此配置用于本机演示。

## 后续公开上线

先确认以上验收问题能用，再选择能运行 Docker/Python、PostgreSQL pgvector 和 Redis 的托管环境。公开访问需要 HTTPS、独立凭据与访问权限配置；本项目生产模式要求 JWT。不要直接把本机管理员 API Key 发给所有访客。GitHub 存放源码，本地 Docker 负责本机运行，常驻云服务负责关机后仍可访问的公网网址。

当前文件只提供本地启动流程，不代表已创建云服务或公开网址。
