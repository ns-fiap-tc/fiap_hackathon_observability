# Configurações de Monitoramento

Este diretório contém as configurações para os componentes de monitoramento da stack de observabilidade.

## Arquivos

- `otel-collector-config.yaml`: Configuração do OpenTelemetry Collector para receber métricas dos microsserviços e exportar para Prometheus
- `prometheus.yml`: Configuração do Prometheus para scraping de métricas do cluster Kubernetes e dos microsserviços

## Configuração do OpenTelemetry Collector

O collector está configurado para:

- Receber métricas via OTLP (gRPC na porta 4317 e HTTP na porta 4318)
- Processar e enriquecer as métricas com labels de serviço
- Exportar métricas para Prometheus na porta 8889

## Configuração do Prometheus

O Prometheus está configurado para:

- Scraping automático de pods e serviços Kubernetes com anotações específicas
- Coleta de métricas do OpenTelemetry Collector
- Labels externos para identificação do cluster e ambiente
