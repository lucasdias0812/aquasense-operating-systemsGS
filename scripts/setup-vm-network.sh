#!/usr/bin/env bash
# AquaSense - IP fixo no adaptador Host-Only (secundario) de uma VM VirtualBox.
# Adaptador 1: NAT/DHCP (internet) - NAO ALTERADO.
# Adaptador 2: Host-Only - IP fixo sem gateway.
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_root
[[ "$(ps -p 1 -o comm= | xargs)" == systemd ]] || { echo 'Execute em Ubuntu Server com systemd.'; exit 1; }
command -v netplan >/dev/null || { echo 'Netplan nao instalado.'; exit 1; }
if [[ $# -ne 2 ]]; then
  echo "Uso: sudo bash scripts/setup-vm-network.sh INTERFACE_HOSONLY IP/CIDR"
  echo "Exemplo: sudo bash scripts/setup-vm-network.sh enp0s8 192.168.56.20/24"
  echo 'Descubra a interface correta com: ip -br link'
  exit 2
fi
IFACE="$1"; ADDRESS="$2"
[[ "$IFACE" =~ ^[a-zA-Z0-9_.:-]+$ ]] || { echo 'Nome de interface invalido.'; exit 2; }
[[ "$ADDRESS" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[12][0-9]|3[0-2])$ ]] || { echo 'CIDR invalido.'; exit 2; }
[[ "$IFACE" != lo ]] || { echo 'Nao use interface loopback.'; exit 2; }
ip link show dev "$IFACE" >/dev/null || { echo "Interface $IFACE nao encontrada."; exit 1; }
# Bloquear a interface usada para a rota padrao (adaptador NAT).
DEFAULT_IFACE="$(ip -4 route show default | awk 'NR==1{for(i=1;i<=NF;i++) if($i=="dev")print $(i+1)}')"
[[ "$IFACE" != "$DEFAULT_IFACE" ]] || { echo "ERRO: $IFACE e a interface de Internet/NAT. Nao modificar!"; exit 1; }
# Checar IPs (4 octetos de 0..255)
IP="${ADDRESS%/*}"
IFS=. read -r a b c d <<< "$IP"
for octet in "$a" "$b" "$c" "$d"; do (( 10#$octet <= 255 )) || { echo 'IP invalido (octeto >255).'; exit 2; }; done
[[ "${ADDRESS#*/}" == 24 ]] || { echo 'Para o exemplo Host-Only use mascara /24.'; exit 2; }
FILE=/etc/netplan/90-aquasense-hostonly.yaml
if [[ -e "$FILE" ]]; then cp -a "$FILE" "${FILE}.bak"; fi
cat > "$FILE" <<YAML
# AquaSense - interface secundaria Host-Only; NAT permanece via DHCP.
network:
  version: 2
  renderer: networkd
  ethernets:
    $IFACE:
      dhcp4: false
      optional: true
      addresses:
        - $ADDRESS
YAML
chmod 600 "$FILE"
if ! netplan generate; then
  if [[ -f "${FILE}.bak" ]]; then mv -f "${FILE}.bak" "$FILE"; else rm -f "$FILE"; fi
  echo 'Falha de sintaxe: configuracao anterior restaurada.'
  exit 1
fi
log INFO "Netplan IP fixo gerado: interface=$IFACE endereco=$ADDRESS; NAT=$DEFAULT_IFACE preservado."
echo 'Arquivo criado:'; cat "$FILE"
echo 'IMPORTANTE: execute sudo netplan try no console da VM e confirme com ENTER se a rede continuar funcional.'
echo 'Depois: ip -br addr ; ip route ; getent hosts ubuntu.com'
