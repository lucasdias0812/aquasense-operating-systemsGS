#!/usr/bin/env bash
set -Eeuo pipefail
source /opt/aquasense/bin/common.sh
# /proc/stat: ocioso vs total em duas medições com intervalo de 1 s.
read -r _ u n s idle io irq sirq steal _ < /proc/stat
prev_idle=$((idle+io)); prev_total=$((u+n+s+idle+io+irq+sirq+steal))
sleep 1
read -r _ u n s idle io irq sirq steal _ < /proc/stat
now_idle=$((idle+io)); now_total=$((u+n+s+idle+io+irq+sirq+steal))
delta_total=$((now_total-prev_total)); delta_idle=$((now_idle-prev_idle))
if (( delta_total > 0 )); then cpu=$((100*(delta_total-delta_idle)/delta_total)); else cpu=0; fi
read -r mem_total mem_available < <(awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} END {print t,a}' /proc/meminfo)
mem=$((100*(mem_total-mem_available)/mem_total))
disk=$(df -P / | awk 'NR==2 {gsub(/%/,"",$5);print $5}')
log INFO "MONITOR cpu=${cpu}% memoria=${mem}% disco=${disk}%"
((cpu >= ${CPU_LIMIT:-85})) && log ALERT "ALERTA CPU ${cpu}% >= ${CPU_LIMIT:-85}%" || true
((mem >= ${MEM_LIMIT:-85})) && log ALERT "ALERTA MEMORIA ${mem}% >= ${MEM_LIMIT:-85}%" || true
((disk >= ${DISK_LIMIT:-85})) && log ALERT "ALERTA DISCO ${disk}% >= ${DISK_LIMIT:-85}%" || true
if ! systemctl is-active --quiet aquasense-app.service; then
  log ERROR 'Aplicacao aquasense-app.service esta inativa'
fi
