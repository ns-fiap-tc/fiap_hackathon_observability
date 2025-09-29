# Configurações do Grafana

Este diretório contém todas as configurações necessárias para o Grafana funcionar com provisioning automático.

## Estrutura

```
grafana/
├── dashboards/                    # Dashboards JSON
│   ├── microservices-overview.json
│   └── otel-collector-monitoring.json
├── datasources/                   # Configuração de data sources (legado)
│   └── prometheus.yaml
└── provisioning/                  # Configuração de provisionamento
    ├── dashboards/
    │   └── dashboard.yaml
    └── datasources/
        └── prometheus.yaml
```

## Dashboards Incluídos

### 1. Microsserviços - Visão Geral

- **CPU Usage**: Monitoramento de uso de CPU por serviço
- **Memory Usage**: Monitoramento de uso de memória JVM
- **HTTP Requests**: Taxa de requisições por segundo
- **Response Time**: Tempo de resposta (50th e 95th percentis)
- **Error Rate**: Taxa de erro por serviço

### 2. OpenTelemetry Collector - Monitoramento

- **Métricas Recebidas**: Taxa de métricas recebidas por segundo
- **Métricas Exportadas**: Taxa de métricas exportadas para Prometheus
- **Uso de Memória**: Monitoramento de memória do collector
- **CPU Usage**: Uso de CPU do collector
- **Erros de Processamento**: Métricas recusadas e falhas de envio

## Data Sources

- **Prometheus**: Configurado para conectar automaticamente com o serviço Prometheus no cluster

## Provisioning

O Grafana está configurado para:

- Carregar automaticamente os data sources
- Carregar automaticamente os dashboards
- Permitir atualizações via UI
- Atualizar configurações a cada 10 segundos

## Como Adicionar Novos Dashboards

1. Crie o arquivo JSON do dashboard em `dashboards/`
2. Adicione o arquivo ao ConfigMap `grafana_dashboard_files` no Terraform
3. Faça o deploy da atualização

## Como Adicionar Novos Data Sources

1. Crie o arquivo YAML do data source em `provisioning/datasources/`
2. Adicione o arquivo ao ConfigMap `grafana_datasources` no Terraform
3. Faça o deploy da atualização
