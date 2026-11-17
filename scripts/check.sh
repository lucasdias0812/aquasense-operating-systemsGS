#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
port=$(sed -n 's/^APP_PORT=//p' /etc/aquasense/aquasense.conf | tail -1)
port=${port:-8080}
echo '=== Identidade e rede ==='; hostnamectl --static; ip -br addr; ip route | head -5; getent hosts localhost
echo '=== Serviços ==='; systemctl is-enabled aquasense-app.service aquasense-monitor.service; systemctl is-active aquasense-app.service aquasense-monitor.service
echo '=== Aplicação ==='; curl --fail --silent --show-error --max-time 5 "http://127.0.0.1:${port}/health" || { echo 'Verifique se a aplicação real possui a rota /health; teste / ou /swagger.'; exit 1; }
echo; echo '=== Logs ==='; tail -n 12 /var/log/aquasense/operations.log
