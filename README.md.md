# AquaSense | Infraestrutura Linux

**FIAP — Global Solution 2026.2 | Operating Systems**

**Integrantes:** [Inserir nomes completos e RMs antes da entrega]

## Visão geral

O AquaSense é um projeto acadêmico CitizenTech voltado à apresentação de informações sobre chuva e histórico de alagamentos urbanos. Este repositório reúne a infraestrutura Linux para hospedar uma aplicação web e executar rotinas automatizadas de provisionamento, monitoramento e auditoria.

A implantação utiliza Ubuntu Server 24.04 LTS em uma máquina virtual VirtualBox. O provisionamento é realizado por scripts Bash, com gerenciamento de serviços pelo `systemd` e configurações de rede pelo Netplan.

**Escopo da aplicação:** `app/demo_server.py` é um servidor HTTP demonstrativo para validar o ambiente. Ele não representa o backend REST definitivo do grupo nem implementa integrações de dados, sensores ou aprendizado de máquina.

## Componentes

| Componente | Responsabilidade |
|---|---|
| `scripts/install.sh` | Instala dependências, prepara usuários, diretórios, permissões e serviços |
| `scripts/network.sh` | Configura hostname e registra informações de rede |
| `scripts/setup-vm-network.sh` | Gera a configuração Netplan de IP fixo na interface Host-Only |
| `scripts/setup-vm-dns.sh` | Gera a configuração Netplan de DNS para a interface NAT |
| `scripts/start-app.sh` | Inicialização da aplicação |
| `scripts/monitor.sh` | Coleta utilização de CPU, memória RAM e armazenamento |
| `scripts/monitor-daemon.sh` | Execução periódica do monitoramento |
| `scripts/test-failure.sh` | Testes controlados de alerta, erro e recuperação do serviço |
| `scripts/check.sh` | Verificação da implantação |
| `scripts/deploy-dotnet.sh` | Apoio à implantação de backend .NET publicado, quando disponível |
| `systemd/` | Unidades dos serviços da aplicação e monitoramento |
| `config/` | Exemplo de configuração do ambiente |
| `evidencias/` | Capturas de tela de testes executados na máquina virtual |

## Ambiente

- Ubuntu Server 24.04 LTS (VirtualBox)
- 2 GB de RAM, 2 CPUs e disco virtual de 25 GB
- Adaptador 1: NAT com DHCP, para acesso à internet
- Adaptador 2: Host-Only, para endereçamento fixo de laboratório
- Aplicação HTTP demonstrativa na porta `8080`
- Serviços `aquasense-app` e `aquasense-monitor`

## Provisionamento

Clone este repositório na máquina Ubuntu e execute na pasta raiz:

```bash
sudo bash scripts/install.sh
sudo bash scripts/check.sh
```

Verifique os serviços e a resposta da aplicação:

```bash
systemctl status aquasense-app --no-pager
systemctl status aquasense-monitor --no-pager
curl http://127.0.0.1:8080/health
```

## Configuração de rede

A interface NAT mantém DHCP e a rota padrão. Para configurar IP fixo na placa Host-Only, identifique primeiro os nomes de interface e a sub-rede existente no VirtualBox:

```bash
ip -br link
ip route
```

Após confirmar uma interface secundária e um endereço disponível na rede Host-Only, execute (valores apenas ilustrativos):

```bash
sudo bash scripts/setup-vm-network.sh enp0s8 192.168.56.20/24
sudo netplan try
```

Para configurar DNS na interface NAT (substitua `enp0s3` pelo nome real):

```bash
sudo bash scripts/setup-vm-dns.sh enp0s3
sudo netplan try
```

Confira as configurações aplicadas:

```bash
hostnamectl
ip -br address
ip route
resolvectl status
getent hosts ubuntu.com
```

**Atenção:** os endereços e nomes de interface acima são exemplos. A configuração deve ser aplicada no console da VM, após verificar a rede, para evitar perda de conectividade.

## Monitoramento e auditoria

O serviço `aquasense-monitor` acompanha CPU, memória RAM e disco periodicamente e registra os resultados em `/var/log/aquasense/operations.log`. O `systemd` supervisiona a execução dos serviços.

```bash
sudo bash /opt/aquasense/bin/monitor.sh
sudo tail -n 30 /var/log/aquasense/operations.log
sudo journalctl -u aquasense-monitor -n 30 --no-pager
```

Controle do serviço:

```bash
sudo systemctl stop aquasense-monitor
sudo systemctl start aquasense-monitor
sudo systemctl restart aquasense-monitor
systemctl is-enabled aquasense-monitor
```

## Testes de falha

```bash
sudo bash scripts/test-failure.sh
sudo grep -E 'RECUPERACAO|ALERTA|FALHA CONTROLADA' /var/log/aquasense/operations.log
sudo journalctl -u aquasense-monitor -n 30 --no-pager
```

O teste provoca a interrupção inesperada do processo de monitoramento para observar a recuperação pelo `systemd`, realiza um teste de limiar para o alerta de CPU e registra uma falha controlada. O teste de limiar não representa carga real elevada de CPU. Uma parada administrativa via `systemctl stop` não é uma falha inesperada.

Após reiniciar a VM, verifique:

```bash
systemctl is-active aquasense-app aquasense-monitor
curl -f http://127.0.0.1:8080/health
```

## Integração com o backend

A infraestrutura inclui um procedimento de implantação para uma API .NET publicada, por meio de `scripts/deploy-dotnet.sh`. A integração depende da versão do runtime, das variáveis de ambiente, do banco de dados e das rotas disponibilizadas pelo backend da equipe. A aplicação demonstrativa deve ser substituída quando o backend estiver disponível e validado.

## Evidências

As capturas de tela da execução real serão incluídas em `evidencias/`, contemplando: instalação, IP e DNS, serviços, aplicação, monitoramento, logs e recuperação de falhas. Os resultados devem corresponder aos testes realizados na máquina virtual.
