#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_root
log INFO 'Teste 1: falha abrupta do daemon de monitoramento (SIGKILL)'
old_pid=$(systemctl show -p MainPID --value aquasense-monitor.service)
[[ "$old_pid" =~ ^[0-9]+$ && "$old_pid" -gt 1 ]] || { echo 'Monitoramento não está em execução'; exit 1; }
kill -KILL "$old_pid"
sleep 6
new_pid=$(systemctl show -p MainPID --value aquasense-monitor.service)
if systemctl is-active --quiet aquasense-monitor.service && [[ "$new_pid" != "$old_pid" ]]; then
  log INFO "RECUPERACAO OK: PID antigo=$old_pid novo=$new_pid"
else
  log ERROR "RECUPERACAO FALHOU antigo=$old_pid novo=$new_pid"; exit 1
fi
log INFO 'Teste 2: alerta controlado de CPU, com limite temporario CPU_LIMIT=0 (sem estressar hardware)'
CPU_LIMIT=0 /opt/aquasense/bin/monitor.sh
log INFO 'Teste 3: falha controlada de comando inválido, registrada no log'
if /bin/bash -c 'comando_aquasense_inexistente' >/dev/null 2>&1; then
  log ERROR 'Erro esperado não aconteceu'; exit 1
else
  log ERROR 'FALHA CONTROLADA: comando_aquasense_inexistente não existe (resultado esperado)'
fi
log INFO 'Verifique log: sudo tail -n 40 /var/log/aquasense/operations.log'
