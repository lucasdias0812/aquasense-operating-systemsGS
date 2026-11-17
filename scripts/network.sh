#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_root
CONF=/etc/aquasense/aquasense.conf
set -a; source "$CONF"; set +a
hostnamectl set-hostname aquasense-linux
# Associa o hostname ao loopback sem substituir entradas existentes.
if ! grep -Eq '(^|[[:space:]])aquasense-linux([[:space:]]|$)' /etc/hosts; then
  printf '127.0.1.1 aquasense-linux\n' >> /etc/hosts
fi
if [[ "${NETWORK_MODE:-dhcp}" == 'static' ]]; then
  : "${NETWORK_INTERFACE:?Informe NETWORK_INTERFACE}"
  : "${STATIC_ADDRESS:?Informe STATIC_ADDRESS em CIDR (ex: 192.168.1.50/24)}"
  : "${STATIC_GATEWAY:?Informe STATIC_GATEWAY}"
  [[ "$NETWORK_INTERFACE" =~ ^[a-zA-Z0-9_.:-]+$ ]] || { echo 'Interface inválida' >&2; exit 1; }
  [[ "$STATIC_ADDRESS" =~ ^[0-9.]+/[0-9]{1,2}$ ]] || { echo 'Endereço estático inválido' >&2; exit 1; }
  [[ "$STATIC_GATEWAY" =~ ^[0-9.]+$ ]] || { echo 'Gateway inválido' >&2; exit 1; }
  command -v netplan >/dev/null || { log ERROR 'netplan não disponível'; exit 1; }
  # O arquivo é gerado de forma reproduzível; aplicação é deliberadamente manual
  # porque netplan apply remoto pode derrubar a conexão.
  {
    echo 'network:'
    echo '  version: 2'
    echo '  ethernets:'
    echo "    $NETWORK_INTERFACE:"
    echo '      dhcp4: false'
    echo "      addresses: [$STATIC_ADDRESS]"
    echo '      routes:'
    echo "        - to: default"
    echo "          via: $STATIC_GATEWAY"
    echo '      nameservers:'
    echo -n '        addresses: ['
    printf '%s' "${DNS_SERVERS:-1.1.1.1 8.8.8.8}" | tr ' ' ','
    echo ']'
  } > /etc/netplan/90-aquasense.yaml
  chmod 600 /etc/netplan/90-aquasense.yaml
  netplan generate
  log WARN 'Rede estática gerada em /etc/netplan/90-aquasense.yaml; aplique via sudo netplan try (pode interromper acesso).'
else
  log INFO 'Rede DHCP mantida; endereçamento atual registrado no log.'
fi
log INFO "HOSTNAME=$(hostname)"
log INFO "IP=$(hostname -I 2>/dev/null || echo indisponivel)"
log INFO "GATEWAY=$(ip route show default 2>/dev/null | head -1 || true)"
log INFO "DNS=$(resolvectl dns 2>/dev/null | head -3 | tr '\n' ' ' || cat /etc/resolv.conf | grep -E '^nameserver' | tr '\n' ' ' || true)"
getent hosts localhost >/dev/null && log INFO 'Teste DNS/hosts localhost OK' || log ERROR 'Teste de resolução localhost falhou'
