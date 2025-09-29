# 🚀 Guia de Configuração - Stack de Observabilidade

Este guia detalha como configurar e fazer o deploy da stack completa de observabilidade para microsserviços.

## 📋 Pré-requisitos

### Ferramentas Necessárias

- **Terraform** >= 1.2.0
- **kubectl** configurado para o cluster EKS
- **AWS CLI** configurado com credenciais
- **Cluster EKS** rodando e acessível

### Permissões AWS Necessárias

- Acesso ao cluster EKS
- Permissões para criar recursos Kubernetes
- Permissões para acessar data sources do EKS

## 🔧 Configuração Inicial

### 1. Configurar Variáveis de Ambiente

Copie o arquivo de exemplo e configure suas variáveis:

```bash
cd terraform
cp env.example .env
```

Edite o arquivo `.env` com suas configurações:

```bash
# Configurações AWS e Kubernetes
AWS_REGION=us-east-1
ENVIRONMENT=dev
CLUSTER_NAME=hacka_cluster
```

### 2. Verificar Conectividade

Teste a conectividade com o cluster:

```bash
kubectl get nodes
kubectl get namespaces
```

### 3. Inicializar Terraform

```bash
cd terraform
terraform init
```

## 🚀 Deploy da Stack

### 1. Planejar o Deploy

```bash
./terraform.sh plan
```

Este comando irá:

- Validar as configurações
- Mostrar os recursos que serão criados
- Verificar dependências

### 2. Aplicar as Configurações

```bash
./terraform.sh apply
```

Confirme com `yes` quando solicitado.

### 3. Verificar o Deploy

```bash
# Verificar namespace
kubectl get namespace observability

# Verificar pods
kubectl get pods -n observability

# Verificar services
kubectl get services -n observability
```

## 📊 Acessar os Serviços

### Port Forward para Desenvolvimento

```bash
# Prometheus
kubectl port-forward -n observability service/prometheus 9090:9090

# Grafana
kubectl port-forward -n observability service/grafana 3000:3000

# OpenTelemetry Collector (para debug)
kubectl port-forward -n observability service/otel-collector 4318:4318
```

### URLs de Acesso

- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **OTEL Collector**: http://localhost:4318

## 🔍 Verificar Funcionamento

### 1. Verificar Prometheus

Acesse http://localhost:9090 e verifique:

- Status → Targets: Deve mostrar targets ativos
- Status → Service Discovery: Deve mostrar descobertas do Kubernetes

### 2. Verificar Grafana

Acesse http://localhost:3000 e verifique:

- Data Sources: Prometheus deve estar configurado
- Dashboards: Deve mostrar os dashboards pré-configurados

### 3. Verificar OpenTelemetry Collector

```bash
# Verificar logs do collector
kubectl logs -n observability deployment/otel-collector

# Verificar métricas do collector
kubectl port-forward -n observability service/otel-collector 8889:8889
curl http://localhost:8889/metrics
```

## 🎯 Configuração de Microsserviços

### Variáveis de Ambiente para Microsserviços

Para cada microsserviço, adicione estas variáveis:

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

### Anotações nos Services Kubernetes

```yaml
apiVersion: v1
kind: Service
metadata:
  name: meu-microservico
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/actuator/prometheus"
spec:
  # ... resto da configuração
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

## 🚨 Troubleshooting Comum

### Pods não iniciam

```bash
# Verificar logs
kubectl logs -n observability deployment/prometheus
kubectl logs -n observability deployment/grafana
kubectl logs -n observability deployment/otel-collector

# Verificar eventos
kubectl get events -n observability --sort-by='.lastTimestamp'
```

### Prometheus não encontra targets

```bash
# Verificar service discovery
kubectl get endpoints -A

# Verificar anotações nos services
kubectl get services -A -o yaml | grep prometheus.io
```

### Grafana não conecta ao Prometheus

```bash
# Verificar conectividade
kubectl exec -n observability deployment/grafana -- nslookup prometheus

# Verificar configuração do datasource
kubectl get configmap grafana-datasources -n observability -o yaml
```

## 📚 Próximos Passos

1. **Integrar microsserviços** seguindo o guia de integração
2. **Configurar alertas** para monitoramento proativo
3. **Personalizar dashboards** para necessidades específicas
4. **Configurar backup** dos dados do Prometheus
5. **Implementar CI/CD** para atualizações automáticas

## 🔗 Links Úteis

- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
- [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/)
- [Grafana Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
