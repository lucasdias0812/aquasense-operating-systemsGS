#!/usr/bin/env bash
set -Eeuo pipefail
source /opt/aquasense/bin/common.sh
log INFO 'Monitoramento iniciado'
trap 'log WARN "Monitoramento recebeu sinal de encerramento"; exit 0' TERM INT
while true; do
  if ! /opt/aquasense/bin/monitor.sh; then
    log ERROR 'Falha na verificacao do monitoramento'
  fi
  sleep "${MONITOR_INTERVAL:-15}" & wait $!
done
