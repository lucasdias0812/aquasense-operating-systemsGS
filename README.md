# AquaSense — Operating Systems | FIAP Global Solution 2026.2

**Status:** infraestrutura e scripts preparados; é preciso executar e coletar evidências reais. Inclui variante VirtualBox + Ubuntu Server.

**TUTORIAL PARA VIRTUALBOX E BIOS/UEFI:** [`docs/GUIA_VIRTUALBOX_UBUNTU_SERVER.md`](docs/GUIA_VIRTUALBOX_UBUNTU_SERVER.md) — comece por ele. **ROTEIRO DE VÍDEO PARA VM:** [`docs/ROTEIRO_VIDEO_VM.md`](docs/ROTEIRO_VIDEO_VM.md).

**Integrantes:** PREENCHER NOMES COMPLETOS E RMs DE TODOS OS INTEGRANTES.

## Objetivo
Provisionar um servidor Ubuntu Linux capaz de executar e monitorar a aplicação AquaSense (CitizenTech). O AquaSense é uma plataforma **acadêmica experimental** para consulta de dados e histórico de alagamentos, não um sistema oficial de alerta.

A pasta `app/demo_server.py` contém apenas um **servidor ilustrativo para demonstrar o deploy de infraestrutura**. **Não** representa o backend REST efetivo, a integração com ESP32 ou o ML descrito no PDF conceitual.

## Arquitetura
- Linux Ubuntu 22.04/24.04, usando WSL2 com systemd habilitado ou VM Ubuntu.
- Bash para instalação e configuração automatizada.
- `aquasense-app.service` para executar a aplicação na porta 8080.
- `aquasense-monitor.service` para amostrar CPU, RAM e armazenamento a cada 15 segundos por padrão.
- Logs de texto em `/var/log/aquasense/operations.log` e journal do systemd.
- Hostname definido como `aquasense-linux`; rede padrão DHCP com auditoria de IP, gateway e DNS. Opção de Netplan estático documentada.

## Pré-requisitos
Ubuntu 22.04 ou 24.04, acesso sudo, apt, acesso à internet para instalar pacotes, systemd como PID 1.

### 1. Baixar e entrar na pasta do projeto
Descompacte o ZIP no Ubuntu. Se ele estiver em `Downloads` no Windows, no WSL normalmente fica em `/mnt/c/Users/SEU_USUARIO/Downloads`.

```bash
cd ~/aquasense-operating-systems
```

### 2. Instalação automática
```bash
sudo bash scripts/install.sh
```

O script instala dependências, cria usuário de sistema sem login, diretórios e permissões, hostname, relatório de rede, unidades systemd, habilita e inicializa os dois serviços. **A rede padrão DHCP existente é preservada**; essa escolha evita perda de conectividade.

### 3. Testar serviços, site e logs
```bash
sudo bash scripts/check.sh
systemctl status aquasense-app.service --no-pager
systemctl status aquasense-monitor.service --no-pager
curl http://localhost:8080/health
sudo tail -n 30 /var/log/aquasense/operations.log
sudo journalctl -u aquasense-monitor -n 30 --no-pager
```

Deve aparecer `active (running)` para os serviços, uma resposta JSON com `status: ok` para o servidor **demo** e linhas de monitoramento. Após instalar, aguarde pelo menos 20 segundos para obter leituras.

### 4. Executar testes de falha controlada
```bash
sudo bash scripts/test-failure.sh
sudo journalctl -u aquasense-monitor -n 30 --no-pager
sudo grep -E 'RECUPERACAO|ALERTA|FALHA CONTROLADA' /var/log/aquasense/operations.log
```

O script mata o processo principal do monitor com SIGKILL; `Restart=always` deve recriá-lo. Gera um alerta testando `CPU_LIMIT=0` **somente nessa execução**, sem sobrecarregar o computador; registra intencionalmente erro de comando inexistente. Isso é simulação de limiar, **não prova consumo real elevado de CPU**.

### 5. Parar, iniciar e reiniciar o serviço
```bash
sudo systemctl stop aquasense-monitor
sudo systemctl start aquasense-monitor
sudo systemctl restart aquasense-monitor
systemctl is-enabled aquasense-monitor
```

**Atenção:** `systemctl stop` é uma parada voluntária: o systemd não reativa automaticamente o serviço quando o administrador manda parar. A recuperação automática se prova com falha inesperada (SIGKILL no processo) ou reinicialização do ambiente, não por `stop`.

### 6. Reproduzir após reiniciar Ubuntu
Em VM: reinicie a VM; em WSL: no PowerShell use `wsl --shutdown` e abra o Ubuntu novamente. Teste:
```bash
systemctl is-active aquasense-app aquasense-monitor
curl -f http://localhost:8080/health
```

## Variante recomendada para PC Windows com 8 GB de RAM: VirtualBox + Ubuntu Server

Siga o [guia completo com BIOS/UEFI](docs/GUIA_VIRTUALBOX_UBUNTU_SERVER.md). Nesta variante, adaptador 1 NAT mantém internet; adaptador 2 Host-Only recebe IP fixo via `scripts/setup-vm-network.sh`. `scripts/setup-vm-dns.sh` permite definir DNS na interface NAT, **preservando DHCP**. Ambos geram arquivos Netplan e deixam a aplicação em duas etapas (`sudo netplan try` no console), para evitar cortes de conexão. O roteiro do vídeo está [aqui](docs/ROTEIRO_VIDEO_VM.md).

## Infraestrutura e rede
Por padrão, `NETWORK_MODE=dhcp` preserva a configuração de DHCP já fornecida pelo WSL/VM e registra IP, rota e DNS. Confira:
```bash
hostnamectl
ip -br address
ip route
resolvectl status
getent hosts localhost
```

Opcional, **apenas em VM Ubuntu com Netplan e acesso ao console**, configurar IP estático editando `/etc/aquasense/aquasense.conf`:
```
NETWORK_MODE=static
NETWORK_INTERFACE=enp0s3
STATIC_ADDRESS=192.168.1.50/24
STATIC_GATEWAY=192.168.1.1
DNS_SERVERS="1.1.1.1 8.8.8.8"
```
**Use valores da sua rede; os acima são exemplos e podem NÃO funcionar.** Depois:
```bash
sudo bash scripts/network.sh
sudo netplan try
```
O script gera e valida `/etc/netplan/90-aquasense.yaml`, mas não aplica automaticamente a alteração arriscada. Netplan pode conflitar com configurações anteriores da VM; examine `sudo netplan get` antes da mudança. Não usar este procedimento de IP estático no WSL.

## Integrar o backend REST real do grupo
O PDF de proposta identifica backend REST e serviços .NET, mas **não fornece projeto fonte, DLL, versão do .NET, variáveis necessárias ou banco de dados**. Essas escolhas devem ser confirmadas com a equipe.

1. Peça ao responsável pelo backend o **código**, a **versão alvo do .NET**, a **porta**, as **variáveis de ambiente**, a **rota de health-check** e as dependências de banco.
2. No computador com o SDK certo, dentro da pasta do projeto, execute (ajuste o caminho):
   ```bash
   dotnet publish -c Release -o ./publish
   ```
3. No Ubuntu, instale o **ASP.NET Core Runtime da mesma versão principal** exigida pela API, via instruções oficiais da Microsoft para a versão do seu Ubuntu. Verifique `dotnet --list-runtimes`.
4. Copie a pasta `publish` para dentro do Ubuntu, entre nesta pasta do repositório e execute:
   ```bash
   sudo bash scripts/deploy-dotnet.sh /CAMINHO/ATE/publish AquaSense.Api.dll
   ```
   Substitua `AquaSense.Api.dll` pelo nome correto. O script interrompe o servidor demo, copia o publish, muda o modo de execução para dotnet e reinicia o serviço.
5. Coloque eventuais segredos de configuração **fora do Git**, em mecanismo seguro. Para .NET, configure as variáveis necessárias em `/etc/aquasense/aquasense.conf` e reinicie o serviço. Nunca comite senhas.
6. Verifique `sudo journalctl -u aquasense-app -n 100 --no-pager`. Ajuste o health-check em `scripts/check.sh` se a API real não tiver `/health`.

**Observação:** a estratégia .NET é uma adaptação planejada com base na arquitetura do PDF. Não é possível garantir que funcione com o backend real sem conhecer as dependências e configurações do grupo. Banco de dados, migrações e integrações adicionais devem ser adicionados quando o backend estiver disponível.

## Onde estão os arquivos
```
app/demo_server.py             API ilustrativa de infraestrutura
config/aquasense.conf.example Configuração inicial
scripts/install.sh            Provisionamento automatizado
scripts/network.sh            Hostname, IP, DNS e rede
scripts/start-app.sh          Escolha do runtime da aplicação
scripts/deploy-dotnet.sh      Substituição pelo backend .NET publicado
scripts/monitor.sh           Medição pontual de CPU, RAM e disco
scripts/monitor-daemon.sh    Loop do serviço de monitoramento
scripts/test-failure.sh       Simulação de falhas e alertas
scripts/check.sh              Verificações básicas pós-instalação
systemd/*.service            Unidades da aplicação e monitoramento
evidencias/                   Capturas de tela (preencher)
docs/                         Guias adicionais
```

## Evidências a coletar
1. `hostnamectl`, `ip -br address`, `ip route` e DNS.
2. Terminal do `sudo bash scripts/install.sh` concluído sem erros.
3. `systemctl status aquasense-app aquasense-monitor` ativos.
4. Navegador mostrando `http://localhost:8080/health` — distinguir demo de aplicação real.
5. Saída do `sudo tail -n 30 /var/log/aquasense/operations.log` com CPU, RAM e disco.
6. Saída `sudo bash scripts/test-failure.sh` comprovando PID substituído e alerta.
7. `journalctl` comprovando reinício do monitor e, se possível, serviços ativos após reiniciar Ubuntu.

Grave telas **reais**, não prints fabricados. Coloque-as em `evidencias/` e adicione os links no README para avaliação.

## Vídeo (até 7 min)
Ver `docs/ROTEIRO_VIDEO.md`.

## Limitações e critérios
- O Ubuntu precisa estar instalado e **rodando com systemd**.
- Com DHCP no WSL, IP/DNS são administrados pelo WSL/Windows; o script os inspeciona e registra, mas **não os altera de maneira irrestrita**.
- A execução em VM oferece controle de rede mais completo.
- O demo só comprova a hospedagem de um aplicativo web simples; não substitui integrar a aplicação real da disciplina.
- A tolerância a falhas automática usa reinício do daemon em caso de falha, não ignora uma parada voluntária via `systemctl stop`.
- O instalador deve ser testado primeiro numa VM/WSL de estudo, pois modifica hostname e instala serviços como root.

## Entrega
Compartilhar **link do GitHub** e **vídeo de até 7 minutos**, com nomes de todos os integrantes e evidências. Prazo informado no TXT: **19/11/2026 às 23:59**.
