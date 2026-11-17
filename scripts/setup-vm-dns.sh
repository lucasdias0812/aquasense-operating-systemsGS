#!/usr/bin/env bash
# Configura DNS no adaptador NAT, preservando seu endereco IPv4 via DHCP.
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_root
[[ $# -eq 1 ]] || { echo 'Uso: sudo bash scripts/setup-vm-dns.sh INTERFACE_NAT'; exit 2; }
IFACE="$1"
[[ "$IFACE" =~ ^[a-zA-Z0-9_.:-]+$ ]] || { echo 'Interface invalida'; exit 2; }
DEFAULT_IFACE="$(ip -4 route show default | awk 'NR==1{for(i=1;i<=NF;i++) if($i=="dev")print $(i+1)}')"
[[ -n "$DEFAULT_IFACE" && "$IFACE" == "$DEFAULT_IFACE" ]] || { echo "Interface $IFACE nao e a interface de rota padrao ($DEFAULT_IFACE)."; exit 1; }
FILE=/etc/netplan/91-aquasense-dns.yaml
[[ ! -e "$FILE" ]] || cp -a "$FILE" "${FILE}.bak"
cat > "$FILE" <<YAML
# AquaSense - DNS definido via Netplan na interface NAT.
network:
  version: 2
  renderer: networkd
  ethernets:
    $IFACE:
      dhcp4: true
      dhcp4-overrides:
        use-dns: false
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
YAML
chmod 600 "$FILE"
if ! netplan generate; then
  if [[ -f "${FILE}.bak" ]]; then mv -f "${FILE}.bak" "$FILE"; else rm -f "$FILE"; fi
  exit 1
fi
log INFO "DNS Netplan gerado na interface NAT $IFACE (DHCP mantido)"
echo "Arquivo: $FILE"
echo 'Aplique apenas via sudo netplan try no console da VM; confirme se a resolucao continuar funcionando.'
