# 🚀 Repositório Centralizado de Observabilidade

## 📋 Visão Geral

Este guia descreve como criar e configurar um **repositório centralizado** para gerenciar toda a stack de observabilidade dos microsserviços do sistema de upload de vídeo.

## 🏗️ Estrutura do Repositório

```
observability-stack/
├── terraform/
│   ├── kubernetes-observability.tf      # Stack completa de observabilidade
│   ├── monitoring/
│   │   ├── otel-collector-config.yaml  # Configuração do OpenTelemetry Collector
│   │   ├── prometheus.yml              # Configuração do Prometheus
│   │   └── README.md                   # Documentação das configurações
│   ├── providers.tf                    # Providers AWS e Kubernetes
│   ├── variables.tf                    # Variáveis do Terraform
│   ├── data.tf                         # Data sources
│   └── terraform.sh                    # Script de execução
├── grafana/
│   ├── dashboards/                     # Dashboards JSON
│   ├── datasources/                    # Configuração de data sources
│   └── provisioning/                   # Configuração de provisionamento
├── docs/
│   ├── SETUP_GUIDE.md                  # Guia de configuração
│   ├── MICROSERVICES_INTEGRATION.md    # Como integrar microsserviços
│   └── TROUBLESHOOTING.md              # Guia de troubleshooting
└── README.md                           # Documentação principal
```

## 🚀 Configuração do Repositório

### 1. Criar Estrutura de Diretórios

```bash
mkdir -p observability-stack/{terraform/monitoring,grafana/{dashboards,datasources,provisioning},docs}
```

### 2. Arquivos Terraform Necessários

#### `terraform/providers.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.hacka_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.hacka_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.hacka_cluster_auth.token
}
```

#### `terraform/variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "hacka_cluster"
}
```

#### `terraform/data.tf`

```hcl
data "aws_eks_cluster" "hacka_cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "hacka_cluster_auth" {
  name = data.aws_eks_cluster.hacka_cluster.name
}
```

### 3. Configurações de Monitoramento

#### `terraform/monitoring/otel-collector-config.yaml`

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    limit_mib: 512
  resource:
    attributes:
      - key: service.name
        from_attribute: service.name
        action: insert
      - key: service.version
        from_attribute: service.version
        action: insert

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
    namespace: "microservices"
    const_labels:
      cluster: "hacka_cluster"
      environment: "production"

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, resource, batch]
      exporters: [prometheus]
```

#### `terraform/monitoring/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: "hacka_cluster"
    environment: "production"

scrape_configs:
  # OpenTelemetry Collector metrics
  - job_name: "otel-collector"
    static_configs:
      - targets: ["otel-collector:8889"]
    scrape_interval: 5s

  # Microsserviços via Actuator
  - job_name: "microservices"
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
            - default
    relabel_configs:
      - source_labels:
          [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels:
          [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: kubernetes_name

  # Kubernetes cluster metrics
  - job_name: "kubernetes-pods"
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels:
          [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
```

### 4. Script de Deploy

#### `terraform/terraform.sh`

```bash
#!/bin/bash

# Carrega as variáveis do arquivo .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "[terraform] Erro: Arquivo .env não encontrado."
    exit 1
fi

# Verifica se o método foi passado como argumento
if [ -z "$1" ]; then
    echo "[terraform] Erro: Nenhum método especificado (plan, apply, etc.)."
    exit 1
fi

METHOD=$1
shift

PARAMS="$@"

terraform $METHOD $PARAMS \
-var "aws_region=$AWS_REGION" \
-var "environment=$ENVIRONMENT" \
-var "cluster_name=$CLUSTER_NAME"
```

### 5. Configuração do Grafana

#### `grafana/datasources/prometheus.yaml`

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    access: proxy
    isDefault: true
    editable: true
```

#### `grafana/provisioning/dashboards/dashboard.yaml`

```yaml
apiVersion: 1

providers:
  - name: "default"
    orgId: 1
    folder: ""
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
```

### 6. Dashboards de Exemplo

#### `grafana/dashboards/microservices-overview.json`

```json
{
  "dashboard": {
    "title": "Microsserviços - Visão Geral",
    "panels": [
      {
        "title": "CPU Usage - Todos os Serviços",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(process_cpu_seconds_total[5m])",
            "legendFormat": "{{service}} - {{application}}"
          }
        ]
      },
      {
        "title": "Memory Usage - Todos os Serviços",
        "type": "graph",
        "targets": [
          {
            "expr": "jvm_memory_used_bytes",
            "legendFormat": "{{service}} - {{application}}"
          }
        ]
      },
      {
        "title": "HTTP Requests - Todos os Serviços",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_server_requests_total[5m])",
            "legendFormat": "{{service}} - {{application}}"
          }
        ]
      }
    ]
  }
}
```

## 🔧 Como Usar

### 1. Deploy da Stack de Observabilidade

```bash
cd observability-stack/terraform
./terraform.sh apply
```

### 2. Integração com Microsserviços

Para cada microsserviço, adicione estas variáveis de ambiente:

```bash
# Configuração OTLP (OpenTelemetry) - MESMO ENDPOINT PARA TODOS
MANAGEMENT_METRICS_EXPORT_OTLP_ENDPOINT=http://otel-collector:4318/v1/metrics
MANAGEMENT_METRICS_EXPORT_OTLP_PROTOCOL=http/protobuf

# Labels para identificar cada microsserviço
MANAGEMENT_METRICS_TAGS_APPLICATION=upload-service          # ALTERE POR MICROSSERVIÇO
MANAGEMENT_METRICS_TAGS_SERVICE=ms-upload                   # ALTERE POR MICROSSERVIÇO

# Configuração Actuator
MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,metrics,prometheus
MANAGEMENT_METRICS_DISTRIBUTION_PERCENTILES_HISTOGRAMS=true
MANAGEMENT_METRICS_DISTRIBUTION_MINIMUM_EXPECTED_VALUE=1ms
MANAGEMENT_METRICS_DISTRIBUTION_MAXIMUM_EXPECTED_VALUE=30s
```

### 3. Anotações nos Services

```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/actuator/prometheus"
```

## 📊 Benefícios da Arquitetura Centralizada

- ✅ **Repositório único** para toda a observabilidade
- ✅ **Configuração centralizada** de todos os componentes
- ✅ **Reutilização** entre diferentes projetos
- ✅ **Manutenção simplificada** de dashboards e alertas
- ✅ **Versionamento** das configurações de monitoramento
- ✅ **Escalabilidade** para novos microsserviços

## 🎯 Próximos Passos

1. **Criar o repositório** `observability-stack`
2. **Migrar configurações** do microsserviço atual
3. **Configurar CI/CD** para deploy automático
4. **Integrar com outros microsserviços**
5. **Criar dashboards específicos** por serviço

## 📚 Documentação Adicional

- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
- [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/)
- [Grafana Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)
