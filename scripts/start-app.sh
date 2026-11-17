#!/usr/bin/env bash
set -Eeuo pipefail
cd /opt/aquasense/app
case "${APP_MODE:-demo}" in
  demo) exec /usr/bin/python3 /opt/aquasense/app/demo_server.py ;;
  dotnet)
    [[ -f "/opt/aquasense/app/${DOTNET_DLL:-AquaSense.Api.dll}" ]] || { echo 'DLL .NET não encontrada no diretório da aplicação' >&2; exit 1; }
    exec /usr/bin/dotnet "/opt/aquasense/app/${DOTNET_DLL:-AquaSense.Api.dll}"
    ;;
  *) echo "APP_MODE inválido: ${APP_MODE}" >&2; exit 1 ;;
esac
