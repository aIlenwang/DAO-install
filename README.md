# DAO installation bootstrap

This public repository contains only the standalone installation scripts and their license. DAO source code and release packages remain in the private [aIlenwang/DAO](https://github.com/aIlenwang/DAO) repository.

## 主站

支持 Debian 12/13、Ubuntu 22.04/24.04，Linux amd64/arm64 和 systemd。先配置域名解析和 80/443 端口，然后执行（替换域名）：

```bash
curl -fsSL https://raw.githubusercontent.com/aIlenwang/DAO-install/main/install-main.sh | sudo bash -s -- --version v0.4.0-rc.1 --domain dao.example.com
```

也可用 `wget -qO-` 替代 `curl -fsSL`。私有安装包需要 GitHub 只读授权：脚本会隐藏输入 Token，或传入 `--github-token-file /root/dao-readonly-token`。推荐 fine-grained PAT，仅授予 DAO 发行仓库 Contents: Read-only。凭据只由主站保存，用于自身和节点的发行下载；不写入命令 URL，也不下发到 Worker。

不指定 `--version` 时只安装最新正式版。当前试部署版本为 `v0.4.0-rc.1`，请明确指定。安装器校验 SHA256，自动准备数据库、服务和管理员。初始密码在 `/etc/dao/admin-password`，运行后配置 LLM 与业务所需凭据。

## Worker

在主站“Worker 节点”添加节点，填写主站 HTTPS 地址和容量，在“安装 Worker 节点”生成一次性命令，复制到对应 VPS 执行。安装码 15 分钟有效，仅绑定该节点；不用手工上传 JSON，不需要 GitHub Token。

节点直接从 GitHub 下载配套版本，准备本机 PostgreSQL 和执行环境，注册后由主站确认就绪。主站不转发安装包。默认执行环境包含基础命令、Python、Node、Chromium 和 Playwright MCP；其他工具的凭据、字典或特殊依赖按需要配置。

## 重装与排障

升级前先暂停/完成任务、停止接收新任务，再停止 `dao` 或 `dao-worker` 服务。安装器拒绝自动覆盖运行中的服务，保留配置、数据库与任务文件，不自动回滚数据库。

安装日志在 `/var/log/dao-install/`（0600，每角色最多 10 份、每份最多 8 MiB）。运行日志：`journalctl -u dao` 或 `journalctl -u dao-worker`。遇到下载中断可以重跑同一命令；已经启动但未就绪时先检查日志和主站节点状态。

Scripts are generated from DAO's `deploy/bootstrap.py` using `scripts/build-bootstrap.py`. No repository credentials, source history, or application binaries are included here. Licensed under AGPL-3.0; see LICENSE.
