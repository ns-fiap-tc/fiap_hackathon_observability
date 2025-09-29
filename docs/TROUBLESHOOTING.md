# 🚨 Guia de Troubleshooting

Este guia ajuda a diagnosticar e resolver problemas comuns na stack de observabilidade.

## 🔍 Diagnóstico Geral

### 1. Verificar Status dos Componentes

```bash
# Verificar namespace
kubectl get namespace observability

# Verificar todos os recursos
kubectl get all -n observability

# Verificar status dos pods
kubectl get pods -n observability -o wide

# Verificar eventos
kubectl get events -n observability --sort-by='.lastTimestamp'
```

### 2. Verificar Logs dos Componentes

```bash
# OpenTelemetry Collector
kubectl logs -n observability deployment/otel-collector --tail=50

# Prometheus
kubectl logs -n observability deployment/prometheus --tail=50

# Grafana
kubectl logs -n observability deployment/grafana --tail=50
```

## 🚨 Problemas Comuns

### 1. Pods não Iniciam

#### Sintomas

- Pods ficam em status `Pending`, `CrashLoopBackOff` ou `Error`
- Logs mostram erros de inicialização

#### Diagnóstico

```bash
# Verificar status detalhado
kubectl describe pod <pod-name> -n observability

# Verificar logs de inicialização
kubectl logs <pod-name> -n observability --previous

# Verificar recursos disponíveis
kubectl top nodes
kubectl describe node <node-name>
```

#### Soluções

```bash
# Verificar recursos disponíveis
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory

# Ajustar recursos no Terraform se necessário
# Editar terraform/kubernetes-observability.tf
```

### 2. OpenTelemetry Collector não Recebe Métricas

#### Sintomas

- Métricas não aparecem no Prometheus
- Logs do collector não mostram métricas recebidas

#### Diagnóstico

```bash
# Verificar conectividade DNS
kubectl exec -n observability deployment/otel-collector -- nslookup otel-collector

# Verificar endpoints
kubectl get endpoints -n observability

# Verificar configuração
kubectl get configmap otel-collector-config -n observability -o yaml

# Testar conectividade
kubectl exec -n observability deployment/otel-collector -- curl -v http://localhost:4318/v1/metrics
```

#### Soluções

```bash
# Verificar se o serviço está exposto corretamente
kubectl get service otel-collector -n observability

# Verificar se as portas estão corretas
kubectl describe service otel-collector -n observability

# Reiniciar o collector
kubectl rollout restart deployment/otel-collector -n observability
```

### 3. Prometheus não Encontra Targets

#### Sintomas

- Targets aparecem como `DOWN` no Prometheus
- Service discovery não encontra serviços

#### Diagnóstico

```bash
# Verificar configuração do Prometheus
kubectl get configmap prometheus-config -n observability -o yaml

# Verificar service discovery
kubectl get services -A -o yaml | grep -A5 -B5 prometheus.io

# Verificar anotações nos serviços
kubectl get services -A -o custom-columns=NAME:.metadata.name,ANNOTATIONS:.metadata.annotations
```

#### Soluções

```bash
# Verificar se os serviços têm as anotações corretas
kubectl get service <service-name> -o yaml | grep -A3 annotations

# Adicionar anotações se necessário
kubectl annotate service <service-name> prometheus.io/scrape=true
kubectl annotate service <service-name> prometheus.io/port=8080
kubectl annotate service <service-name> prometheus.io/path=/actuator/prometheus

# Reiniciar Prometheus
kubectl rollout restart deployment/prometheus -n observability
```

### 4. Grafana não Conecta ao Prometheus

#### Sintomas

- Grafana mostra erro de conexão com Prometheus
- Dashboards não carregam dados

#### Diagnóstico

```bash
# Verificar conectividade DNS
kubectl exec -n observability deployment/grafana -- nslookup prometheus

# Verificar configuração do datasource
kubectl get configmap grafana-datasources -n observability -o yaml

# Testar conectividade
kubectl exec -n observability deployment/grafana -- curl -v http://prometheus:9090/api/v1/query?query=up
```

#### Soluções

```bash
# Verificar se o Prometheus está acessível
kubectl get service prometheus -n observability

# Verificar se o datasource está configurado corretamente
kubectl describe configmap grafana-datasources -n observability

# Reiniciar Grafana
kubectl rollout restart deployment/grafana -n observability
```

### 5. Microsserviços não Enviam Métricas

#### Sintomas

- Métricas não aparecem no collector
- Logs do microsserviço mostram erros de conexão

#### Diagnóstico

```bash
# Verificar configuração do microsserviço
kubectl describe deployment <microservice-name>

# Verificar variáveis de ambiente
kubectl exec deployment/<microservice-name> -- env | grep MANAGEMENT

# Verificar conectividade
kubectl exec deployment/<microservice-name> -- nslookup otel-collector

# Testar endpoint OTLP
kubectl exec deployment/<microservice-name> -- curl -v http://otel-collector:4318/v1/metrics
```

#### Soluções

```bash
# Verificar se as variáveis de ambiente estão corretas
kubectl get deployment <microservice-name> -o yaml | grep -A10 env

# Adicionar variáveis se necessário
kubectl set env deployment/<microservice-name> MANAGEMENT_METRICS_EXPORT_OTLP_ENDPOINT=http://otel-collector:4318/v1/metrics

# Reiniciar o microsserviço
kubectl rollout restart deployment/<microservice-name>
```

## 🔧 Comandos de Diagnóstico Avançado

### 1. Verificar Conectividade de Rede

```bash
# Testar conectividade entre pods
kubectl exec -n observability deployment/otel-collector -- ping prometheus
kubectl exec -n observability deployment/grafana -- ping prometheus

# Verificar resolução DNS
kubectl exec -n observability deployment/otel-collector -- nslookup prometheus.observability.svc.cluster.local
```

### 2. Verificar Recursos do Sistema

```bash
# Verificar uso de CPU e memória
kubectl top pods -n observability

# Verificar uso por nó
kubectl top nodes

# Verificar recursos disponíveis
kubectl describe nodes
```

### 3. Verificar Configurações

```bash
# Verificar todas as configurações
kubectl get configmaps -n observability

# Verificar secrets
kubectl get secrets -n observability

# Verificar RBAC
kubectl get serviceaccounts -n observability
kubectl get clusterroles | grep prometheus
kubectl get clusterrolebindings | grep prometheus
```

## 🚀 Comandos de Recuperação

### 1. Reiniciar Componentes

```bash
# Reiniciar todos os componentes
kubectl rollout restart deployment/otel-collector -n observability
kubectl rollout restart deployment/prometheus -n observability
kubectl rollout restart deployment/grafana -n observability

# Verificar status após reinicialização
kubectl rollout status deployment/otel-collector -n observability
kubectl rollout status deployment/prometheus -n observability
kubectl rollout status deployment/grafana -n observability
```

### 2. Recriar Recursos

```bash
# Recriar namespace (CUIDADO: apaga todos os dados)
kubectl delete namespace observability
kubectl create namespace observability

# Reaplicar configurações
cd terraform
./terraform.sh apply
```

### 3. Limpar e Recriar

```bash
# Limpar recursos específicos
kubectl delete deployment otel-collector -n observability
kubectl delete deployment prometheus -n observability
kubectl delete deployment grafana -n observability

# Reaplicar
cd terraform
./terraform.sh apply
```

## 📊 Monitoramento de Saúde

### 1. Verificar Métricas do Sistema

```bash
# Verificar métricas do collector
kubectl port-forward -n observability service/otel-collector 8889:8889
curl http://localhost:8889/metrics | grep otelcol_receiver_accepted

# Verificar métricas do Prometheus
kubectl port-forward -n observability service/prometheus 9090:9090
curl http://localhost:9090/api/v1/query?query=up
```

### 2. Verificar Dashboards

```bash
# Acessar Grafana
kubectl port-forward -n observability service/grafana 3000:3000
# Acesse http://localhost:3000 e verifique:
# - Data sources estão funcionando
# - Dashboards carregam dados
# - Métricas aparecem em tempo real
```

## 🔍 Logs Detalhados

### 1. Habilitar Logs Verbosos

```bash
# Para OpenTelemetry Collector
kubectl set env deployment/otel-collector OTEL_LOG_LEVEL=debug -n observability

# Para Prometheus
kubectl set env deployment/prometheus PROMETHEUS_LOG_LEVEL=debug -n observability

# Para Grafana
kubectl set env deployment/grafana GF_LOG_LEVEL=debug -n observability
```

### 2. Seguir Logs em Tempo Real

```bash
# Seguir logs de todos os componentes
kubectl logs -f deployment/otel-collector -n observability &
kubectl logs -f deployment/prometheus -n observability &
kubectl logs -f deployment/grafana -n observability &
```

## 🆘 Escalação de Problemas

### Quando Escalar

- Problemas persistem após 30 minutos de troubleshooting
- Múltiplos componentes falhando simultaneamente
- Perda de dados ou métricas críticas
- Problemas de segurança ou acesso

### Informações para Escalação

1. **Status dos componentes**:

   ```bash
   kubectl get all -n observability -o yaml > observability-status.yaml
   ```

2. **Logs dos componentes**:

   ```bash
   kubectl logs deployment/otel-collector -n observability > otel-collector.log
   kubectl logs deployment/prometheus -n observability > prometheus.log
   kubectl logs deployment/grafana -n observability > grafana.log
   ```

3. **Eventos do cluster**:

   ```bash
   kubectl get events -n observability > observability-events.log
   ```

4. **Configurações**:
   ```bash
   kubectl get configmaps -n observability -o yaml > observability-configs.yaml
   ```

## 🔗 Links Úteis

- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/)
- [Prometheus Troubleshooting](https://prometheus.io/docs/prometheus/latest/troubleshooting/)
- [Grafana Troubleshooting](https://grafana.com/docs/grafana/latest/troubleshooting/)
- [OpenTelemetry Collector Troubleshooting](https://opentelemetry.io/docs/collector/troubleshooting/)
