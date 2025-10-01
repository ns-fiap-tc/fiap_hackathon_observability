# 🚀 Stack de Observabilidade Centralizada

Uma solução completa de observabilidade para microsserviços usando OpenTelemetry, Prometheus e Grafana em Kubernetes.

## 📋 Visão Geral

Este projeto implementa uma stack centralizada de observabilidade que permite monitorar múltiplos microsserviços de forma unificada. A arquitetura utiliza:

- **OpenTelemetry Collector**: Recebe métricas de todos os microsserviços via OTLP
- **Prometheus**: Armazena e consulta métricas
- **Grafana**: Visualização e dashboards
- **Kubernetes**: Orquestração e deploy

## 📺 Demo
https://github.com/user-attachments/assets/f62e09ea-9e0c-4f42-a9ed-1bed7a6f9bf7


## 🏗️ Arquitetura

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Microsserviço │    │ OpenTelemetry    │    │   Prometheus   │    │     Grafana     │
│                 │───▶│   Collector      │───▶│                │───▶│                 │
│  (Spring Boot)  │    │                  │    │                │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │                       │
         │                       │                       │                       │
    Métricas OTLP          Processamento           Armazenamento          Visualização
    (HTTP/gRPC)            e Enriquecimento        e Consulta            e Dashboards
```

## 🚀 Início Rápido

### 1. Pré-requisitos

- **Terraform** >= 1.2.0
- **kubectl** configurado para cluster EKS
- **AWS CLI** configurado
- **Cluster EKS** rodando

### 2. Configuração

```bash
# Clone o repositório
git clone <repository-url>
cd fiap_hackathon_observability

# Configure as variáveis
cd terraform
cp env.example .env
# Edite .env com suas configurações
```

### 3. Deploy

#### Deploy Manual

```bash
# Inicializar Terraform
terraform init

# Planejar deploy
./terraform.sh plan

# Aplicar configurações
./terraform.sh apply
```

#### Deploy via GitHub Actions

1. Configure os secrets no GitHub (veja [GitHub Actions Setup](docs/GITHUB_ACTIONS_SETUP.md))
2. Faça push para a branch `main`
3. O deploy será executado automaticamente

### 4. Acessar Serviços

```bash
# Prometheus
kubectl port-forward -n observability service/prometheus 9090:9090
# Acesse: http://localhost:9090

# Grafana
kubectl port-forward -n observability service/grafana 3000:3000
# Acesse: http://localhost:3000 (admin/admin)
```

## 📁 Estrutura do Projeto

```
fiap_hackathon_observability/
├── terraform/                          # Configurações Terraform
│   ├── kubernetes-observability.tf     # Stack completa de observabilidade
│   ├── providers.tf                    # Providers AWS e Kubernetes
│   ├── variables.tf                    # Variáveis do Terraform
│   ├── data.tf                         # Data sources
│   ├── terraform.sh                    # Script de execução
│   ├── env.example                     # Exemplo de variáveis
│   └── monitoring/                     # Configurações de monitoramento
│       ├── otel-collector-config.yaml  # Configuração do OpenTelemetry Collector
│       ├── prometheus.yml              # Configuração do Prometheus
│       └── README.md                   # Documentação das configurações
├── grafana/                           # Configurações do Grafana
│   ├── dashboards/                    # Dashboards JSON
│   │   ├── microservices-overview.json
│   │   └── otel-collector-monitoring.json
│   ├── datasources/                   # Configuração de data sources
│   │   └── prometheus.yaml
│   ├── provisioning/                  # Configuração de provisionamento
│   │   ├── dashboards/
│   │   │   └── dashboard.yaml
│   │   └── datasources/
│   │       └── prometheus.yaml
│   └── README.md                      # Documentação do Grafana
├── docs/                              # Documentação
│   ├── SETUP_GUIDE.md                 # Guia de configuração
│   ├── MICROSERVICES_INTEGRATION.md   # Como integrar microsserviços
│   └── TROUBLESHOOTING.md             # Guia de troubleshooting
├── guide.md                           # Guia original do projeto
└── README.md                          # Este arquivo
```

## 🔧 Componentes

### OpenTelemetry Collector

- **Função**: Recebe métricas de todos os microsserviços via OTLP
- **Portas**: 4317 (gRPC), 4318 (HTTP), 8889 (Prometheus)
- **Configuração**: `terraform/monitoring/otel-collector-config.yaml`

### Prometheus

- **Função**: Armazena e consulta métricas
- **Porta**: 9090
- **Configuração**: `terraform/monitoring/prometheus.yml`
- **Retenção**: 200 horas

### Grafana

- **Função**: Visualização e dashboards
- **Porta**: 3000
- **Usuário**: admin/admin
- **Dashboards**: Provisionamento automático

## 📊 Dashboards Incluídos

### 1. Microsserviços - Visão Geral

- CPU Usage por serviço
- Memory Usage (JVM)
- HTTP Requests por segundo
- Response Time (50th e 95th percentis)
- Error Rate por serviço

### 2. OpenTelemetry Collector - Monitoramento

- Métricas recebidas por segundo
- Métricas exportadas para Prometheus
- Uso de memória e CPU do collector
- Erros de processamento

## 🔗 Integração com Microsserviços

### Configuração Básica

Para cada microsserviço Spring Boot, adicione:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  metrics:
    export:
      otlp:
        endpoint: http://otel-collector:4318/v1/metrics
        protocol: http/protobuf
    tags:
      application: ${spring.application.name}
      service: ms-${spring.application.name}
```

### Anotações no Service Kubernetes

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/actuator/prometheus"
```

## 📚 Documentação

- **[Guia de Configuração](docs/SETUP_GUIDE.md)**: Como configurar e fazer deploy da stack
- **[Integração de Microsserviços](docs/MICROSERVICES_INTEGRATION.md)**: Como integrar seus microsserviços
- **[Troubleshooting](docs/TROUBLESHOOTING.md)**: Resolução de problemas comuns
- **[GitHub Actions Setup](docs/GITHUB_ACTIONS_SETUP.md)**: Configuração de CI/CD

## 🚨 Troubleshooting

### Problemas Comuns

1. **Pods não iniciam**: Verificar recursos disponíveis no cluster
2. **Métricas não aparecem**: Verificar conectividade DNS e configurações OTLP
3. **Prometheus não encontra targets**: Verificar anotações nos serviços
4. **Grafana não conecta**: Verificar configuração do datasource

### Comandos Úteis

```bash
# Verificar status dos componentes
kubectl get all -n observability

# Verificar logs
kubectl logs -n observability deployment/otel-collector
kubectl logs -n observability deployment/prometheus
kubectl logs -n observability deployment/grafana

# Reiniciar componentes
kubectl rollout restart deployment/otel-collector -n observability
kubectl rollout restart deployment/prometheus -n observability
kubectl rollout restart deployment/grafana -n observability
```

## 🔧 Configurações Avançadas

### Personalizar Retenção do Prometheus

Edite `terraform/monitoring/prometheus.yml`:

```yaml
# Adicionar argumento no deployment
args:
  - "--storage.tsdb.retention.time=7d" # 7 dias de retenção
```

### Adicionar Novos Dashboards

1. Crie o arquivo JSON em `grafana/dashboards/`
2. Adicione ao ConfigMap em `terraform/kubernetes-observability.tf`
3. Faça o redeploy

### Configurar Alertas

Adicione regras de alerta em `terraform/monitoring/prometheus.yml`:

```yaml
rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093
```

## 🔧 Configuração do GitHub Actions

### Secrets necessários:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`

### Configurações fixas:

- `AWS_REGION`: `us-east-1`
- `CLUSTER_NAME`: `hacka_cluster`

## 🎯 Benefícios

- ✅ **Centralização**: Todas as métricas em um local
- ✅ **Padronização**: Configuração consistente entre microsserviços
- ✅ **Escalabilidade**: Fácil adição de novos serviços
- ✅ **Manutenibilidade**: Configurações versionadas e documentadas
- ✅ **Observabilidade**: Visibilidade completa do sistema

## 🔗 Links Úteis

- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
- [Prometheus](https://prometheus.io/docs/)
- [Grafana](https://grafana.com/docs/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Kubernetes](https://kubernetes.io/docs/)
