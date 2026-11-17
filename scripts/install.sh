#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/common.sh"
require_root
[[ -f /etc/os-release ]] || { echo 'Linux não identificado'; exit 1; }
command -v apt-get >/dev/null || { echo 'Use Ubuntu/Debian com apt e systemd.'; exit 1; }
[[ "$(ps -p 1 -o comm= | xargs)" == systemd ]] || { echo 'systemd não está ativo; veja instruções para WSL no README.'; exit 1; }
log INFO 'Iniciando provisionamento AquaSense'
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y python3 curl ca-certificates iproute2 dnsutils procps git
log INFO 'Pacotes Linux instalados'
id -u aquasense >/dev/null 2>&1 || useradd --system --home-dir /opt/aquasense --shell /usr/sbin/nologin aquasense
install -d -m 755 /etc/aquasense /opt/aquasense/bin /opt/aquasense/app
install -d -m 750 -o aquasense -g aquasense /var/log/aquasense
if [[ ! -f /etc/aquasense/aquasense.conf ]]; then
  install -m 644 "$ROOT/config/aquasense.conf.example" /etc/aquasense/aquasense.conf
fi
for f in common.sh monitor.sh monitor-daemon.sh start-app.sh; do
  install -m 755 "$ROOT/scripts/$f" "/opt/aquasense/bin/$f"
done
install -m 644 "$ROOT/app/demo_server.py" /opt/aquasense/app/demo_server.py
chown -R aquasense:aquasense /opt/aquasense/app
install -m 644 "$ROOT/systemd/aquasense-app.service" /etc/systemd/system/
install -m 644 "$ROOT/systemd/aquasense-monitor.service" /etc/systemd/system/
"$ROOT/scripts/network.sh"
systemctl daemon-reload
systemctl enable --now aquasense-app.service
systemctl enable --now aquasense-monitor.service
log INFO 'Serviços instalados e ativados'
sleep 2
systemctl --no-pager --full status aquasense-app.service || true
systemctl --no-pager --full status aquasense-monitor.service || true
