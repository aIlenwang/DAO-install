#!/usr/bin/env bash
# Read-only diagnostic collection for installer-managed DAO hosts.
set -euo pipefail
export PATH=/usr/sbin:/usr/bin:/sbin:/bin

if [[ $# -eq 1 && ( $1 == --help || $1 == -h ) ]]; then
  cat <<'HELP'
DAO 一键诊断：主站和 Worker VPS 使用同一条命令。
curl -fsSL https://raw.githubusercontent.com/aIlenwang/DAO-install/main/diagnose.sh | sudo bash
自动识别 /opt/dao/dao 与 /opt/dao-worker/dao-worker；兼容 rc.3 起的离线导出。
只读取状态和近期日志，不安装、不重启、不升级，也不自动上传。
完成后打印本机 .tar.gz 路径，下载该文件用于排障。
HELP
  exit 0
fi
[[ $# -eq 0 ]] || { echo '不支持该参数；查看帮助：bash diagnose.sh --help' >&2; exit 1; }
[[ $EUID -eq 0 ]] || { echo '请使用 sudo bash 或 root 运行，以读取服务日志。' >&2; exit 1; }
[[ $(uname -s) == Linux ]] || { echo '仅支持 Linux。' >&2; exit 1; }
for cmd in mktemp mkdir timeout tar chmod date; do
  command -v "$cmd" >/dev/null || { echo "缺少命令：$cmd；未执行收集。" >&2; exit 1; }
done
if [[ ! -x /opt/dao/dao && ! -x /opt/dao-worker/dao-worker ]]; then
  echo '未找到一键安装的 DAO 主站或 Worker；请在对应 VPS 上运行。' >&2
  exit 1
fi

umask 077
work=$(mktemp -d /tmp/dao-check.XXXXXX)
contents=$work/contents
mkdir "$contents"
trap 'printf "诊断打包未完成；已收集的信息保留在：%s\n" "$work" >&2' ERR

status() {
  local label=$1
  shift
  printf '\n[%s]\n' "$label"
  if timeout -k 2s 15s "$@" </dev/null; then
    :
  else
    printf '未能完整读取此项（退出码 %s），不代表其他项目失败。\n' "$?"
  fi
}
{
  status time date -Is
  status system uname -srmo
  status uptime uptime
  status memory free -h
  status disk df -h / /var/lib /tmp
  status services systemctl show dao dao-worker dao-https postgresql \
    -p Id -p LoadState -p ActiveState -p SubState -p Result \
    -p NRestarts -p ExecMainStatus -p ActiveEnterTimestamp \
    -p MainPID -p MemoryCurrent -p TasksCurrent
  status database-services systemctl list-units --all --type=service \
    --no-pager --plain --no-legend 'postgresql@*.service'
} >"$contents/status.txt" 2>&1

failures=0
export_logs() {
  local role=$1
  shift
  printf '正在收集 %s 的近期日志……\n' "$role"
  if timeout -k 2s 30s "$@" -diagnostics "$contents/$role.zip" \
      </dev/null >"$contents/$role-export.txt" 2>&1; then
    if [[ -s $contents/$role.zip ]]; then
      return
    fi
    printf '程序未生成诊断包。\n' >>"$contents/$role-export.txt"
  fi
  failures=$((failures + 1))
  printf '%s 日志导出未完成，错误记录将随状态信息一起打包。\n' "$role"
}
if [[ -x /opt/dao/dao ]]; then
  export_logs main /opt/dao/dao -data /var/lib/dao/data
fi
if [[ -x /opt/dao-worker/dao-worker ]]; then
  export_logs worker /opt/dao-worker/dao-worker -config /etc/dao-worker/config.json
fi

cat >"$contents/README.txt" <<'INFO'
DAO 按需诊断包：status.txt 为采集时的操作系统/服务状态；main.zip、worker.zip
使用已安装程序的离线导出，包含程序版本、近期本地日志和对应 systemd journal。
缺少某角色表示本机未安装该角色；*-export.txt 记录导出结果，失败时保留部分信息。
诊断 ZIP 中 partial/issues 说明缺失项。服务不存在或当前系统不支持某命令，也会记录。
不含完整配置、密码文件、数据库备份、任务目录或全量模型/工具录制。
常见日志凭据由 DAO 脱敏；业务内容和未标注的秘密仍需在分享前检查。
离线导出不连接数据库或主站，不能仅凭本包证明每个任务、模型和 MCP 都正常。
脚本不安装软件、不更改服务、不升级、不自动上传；原始应用日志保持不变。
INFO

archive=$work/dao-diagnostics.tar.gz
tar -czf "$archive" -C "$contents" .
chmod 600 "$archive"
trap - ERR
if (( failures > 0 )); then
  printf '\n已生成部分诊断包（%s 个角色导出异常）。\n' "$failures"
else
  printf '\n诊断包已生成。\n'
fi
printf '请下载并发送这个文件：%s\n' "$archive"
