#!/usr/bin/env bash
set -Eeuo pipefail
LOG_DIR="${AQUASENSE_LOG_DIR:-/var/log/aquasense}"
log() {
  local level="$1"; shift
  local line="$(date '+%Y-%m-%dT%H:%M:%S%z') [$level] $*"
  printf '%s\n' "$line"
  mkdir -p "$LOG_DIR" 2>/dev/null || true
  if [[ -d "$LOG_DIR" && -w "$LOG_DIR" ]]; then
    printf '%s\n' "$line" >> "$LOG_DIR/operations.log"
  fi
  logger -t aquasense "[$level] $*" 2>/dev/null || true
}
require_root() { if (( EUID != 0 )); then echo 'Execute com sudo.' >&2; exit 1; fi; }
trap 'log ERROR "Falha script=${0##*/} linha=$LINENO comando=$BASH_COMMAND"' ERR
