# DAO installation bootstrap

This public repository contains only the standalone installation scripts and their license. DAO source code and release packages remain in the private [aIlenwang/DAO](https://github.com/aIlenwang/DAO) repository.

## 主站

支持 Debian 12/13、Ubuntu 22.04/24.04，Linux amd64/arm64 和 systemd。无需域名或手填 IP。开放主站 TCP 80/443，脚本自动识别公网 IP：

```bash
curl -fsSL https://raw.githubusercontent.com/aIlenwang/DAO-install/main/install-main.sh | sudo bash -s -- --version v0.4.0-rc.3
```

也可用 `wget -qO-` 替代 `curl -fsSL`。私有安装包需要 GitHub 只读授权：脚本会隐藏输入 Token，或传入 `--github-token-file /root/dao-readonly-token`。已有且有效、能读取 DAO 私有仓库的 Token 也能使用，不强制另建。推荐专用 fine-grained PAT，仅选择 DAO 仓库，授予 Contents: Read-only。凭据只由主站保存，用于自身和节点的发行下载；不写入命令 URL，也不下发到 Worker。

不指定 `--version` 时只安装最新正式版。当前试部署版本为 `v0.4.0-rc.3`，请明确指定。安装器校验 SHA256，自动准备数据库、服务和管理员。初始密码在 `/etc/dao/admin-password`，运行后配置 LLM 与业务所需凭据。

新安装优先通过两个独立 HTTPS 查询源确认公网 IPv4，IPv4 不可用时尝试 IPv6；忽略代理环境变量，避免识别到代理 IP。查询冲突或失败会停止并提示加 `--public-ip 实际IP`，不回退 HTTP。多 IP 或入站/出口地址不同也可手动指定；重装默认沿用已保存地址，显式 `--public-ip auto` 才重新识别。查询只能确认出口地址，公网可达性仍由证书签发与节点接入验证。已有反向代理可使用 `--listen 127.0.0.1` 自行配置 HTTPS。

IP 证书由 Let’s Encrypt 签发，有效期约 6 天；安装器配置独立 `dao-https` 服务自动续期并加载新证书，无需手动重启主站。主站后端仅监听本机。请持续开放 TCP 80/443；证书日志：`journalctl -u dao-https`。有域名也可把 `--public-ip` 换成 `--domain dao.example.com`。IPv6 参数不加方括号，浏览器地址为 `https://[IPv6]`。

## Worker

在主站“Worker 节点”添加节点，填写主站 HTTPS 地址和容量，在“安装 Worker 节点”生成一次性命令，复制到对应 VPS 执行。安装码 15 分钟有效，仅绑定该节点；不用手工上传 JSON，不需要 GitHub Token。

命令格式如下；节点 ID 和安装码必须使用主站生成的实际值，每台 VPS 各一份：

```bash
curl -fsSL https://raw.githubusercontent.com/aIlenwang/DAO-install/main/install-worker.sh | sudo bash -s -- --controller 'https://主站公网IP' --node '节点ID' --enroll '一次性安装码'
```

Worker 无需域名、IP 证书或入站端口，只需出站访问主站 HTTPS 和软件源。

节点直接从 GitHub 下载配套版本，准备本机 PostgreSQL 和执行环境，注册后由主站确认就绪。主站不转发安装包。默认执行环境包含基础命令、Python、Node、Chromium 和 Playwright MCP；其他工具的凭据、字典或特殊依赖按需要配置。

## 重装与排障

升级前先暂停/完成任务、停止接收新任务，再停止 `dao` 或 `dao-worker` 服务。安装器拒绝自动覆盖运行中的服务，保留配置、数据库与任务文件，不自动回滚数据库。

安装日志在 `/var/log/dao-install/`（0600，每角色最多 10 份、每份最多 8 MiB）。运行日志：`journalctl -u dao` 或 `journalctl -u dao-worker`。遇到下载中断可以重跑同一命令；已经启动但未就绪时先检查日志和主站节点状态。

Scripts are generated from DAO's `deploy/bootstrap.py` using `scripts/build-bootstrap.py`. No repository credentials, source history, or application binaries are included here. Licensed under AGPL-3.0; see LICENSE.
