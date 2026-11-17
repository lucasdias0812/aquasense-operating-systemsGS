#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_root
[[ $# -eq 2 ]] || { echo "Uso: sudo bash scripts/deploy-dotnet.sh /caminho/do/publish NomeDaApi.dll"; exit 2; }
SRC="$(realpath "$1")"; DLL="$2"
[[ -d "$SRC" && -f "$SRC/$DLL" ]] || { log ERROR 'Pasta publish ou DLL não encontrada'; exit 1; }
[[ "$DLL" =~ ^[a-zA-Z0-9_.-]+\.dll$ ]] || { echo 'Nome DLL inválido'; exit 1; }
command -v dotnet >/dev/null || { log ERROR 'Runtime .NET ausente. Instale a versão ASP.NET Core correta antes de prosseguir.'; exit 1; }
# Confere se o runtime instalado é compatível; dotnet --list-runtimes exibe versões.
log INFO "Runtimes disponíveis: $(dotnet --list-runtimes | tr '\n' '; ')"
systemctl stop aquasense-app.service || true
find /opt/aquasense/app -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
cp -a "$SRC"/. /opt/aquasense/app/
chown -R aquasense:aquasense /opt/aquasense/app
# Alteração apenas das chaves gerenciadas, preservando demais configurações.
sed -i -E '/^(APP_MODE|DOTNET_DLL|ASPNETCORE_URLS)=/d' /etc/aquasense/aquasense.conf
printf 'APP_MODE=dotnet\nDOTNET_DLL=%s\nASPNETCORE_URLS=http://0.0.0.0:8080\n' "$DLL" >> /etc/aquasense/aquasense.conf
systemctl restart aquasense-app.service
log INFO "Deploy .NET executado: $DLL"
