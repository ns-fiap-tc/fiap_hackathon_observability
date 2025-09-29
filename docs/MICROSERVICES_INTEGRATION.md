# 🔗 Guia de Integração de Microsserviços

Este guia detalha como integrar seus microsserviços com a stack de observabilidade centralizada.

## 📋 Visão Geral da Arquitetura

```
Microsserviços → OpenTelemetry Collector → Prometheus → Grafana
     ↓                    ↓                    ↓         ↓
  Métricas OTLP      Processamento        Armazenamento  Visualização
```

## 🚀 Configuração Básica

### 1. Dependências Maven/Gradle

#### Maven (pom.xml)

```xml
<dependencies>
    <!-- Spring Boot Actuator -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>

    <!-- Micrometer OTLP -->
    <dependency>
        <groupId>io.micrometer</groupId>
        <artifactId>micrometer-registry-otlp</artifactId>
    </dependency>

    <!-- OpenTelemetry (opcional, para traces) -->
    <dependency>
        <groupId>io.opentelemetry</groupId>
        <artifactId>opentelemetry-api</artifactId>
    </dependency>
</dependencies>
```

### 2. Configuração de Propriedades

Adicione ao `application.yml` ou `application.properties`:

#### application.yml

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
    distribution:
      percentiles-histograms: true
      minimum-expected-value: 1ms
      maximum-expected-value: 30s
    tags:
      application: ${spring.application.name}
      service: ms-${spring.application.name}
      environment: ${ENVIRONMENT:dev}
      version: ${APP_VERSION:1.0.0}
```

#### application.properties

```properties
# Actuator
management.endpoints.web.exposure.include=health,info,metrics,prometheus

# OTLP Export
management.metrics.export.otlp.endpoint=http://otel-collector:4318/v1/metrics
management.metrics.export.otlp.protocol=http/protobuf

# Metrics Configuration
management.metrics.distribution.percentiles-histograms=true
management.metrics.distribution.minimum-expected-value=1ms
management.metrics.distribution.maximum-expected-value=30s

# Tags
management.metrics.tags.application=${spring.application.name}
management.metrics.tags.service=ms-${spring.application.name}
management.metrics.tags.environment=${ENVIRONMENT:dev}
management.metrics.tags.version=${APP_VERSION:1.0.0}
```

## 🐳 Configuração Docker/Kubernetes

### 1. Dockerfile

```dockerfile
FROM openjdk:17-jre-slim

WORKDIR /app
COPY target/*.jar app.jar

# Variáveis de ambiente para observabilidade
ENV MANAGEMENT_METRICS_EXPORT_OTLP_ENDPOINT=http://otel-collector:4318/v1/metrics
ENV MANAGEMENT_METRICS_EXPORT_OTLP_PROTOCOL=http/protobuf
ENV MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,metrics,prometheus

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 2. Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: meu-microservico
  labels:
    app: meu-microservico
spec:
  replicas: 2
  selector:
    matchLabels:
      app: meu-microservico
  template:
    metadata:
      labels:
        app: meu-microservico
    spec:
      containers:
        - name: meu-microservico
          image: meu-microservico:latest
          ports:
            - containerPort: 8080
          env:
            - name: MANAGEMENT_METRICS_EXPORT_OTLP_ENDPOINT
              value: "http://otel-collector:4318/v1/metrics"
            - name: MANAGEMENT_METRICS_EXPORT_OTLP_PROTOCOL
              value: "http/protobuf"
            - name: MANAGEMENT_METRICS_TAGS_APPLICATION
              value: "meu-microservico"
            - name: MANAGEMENT_METRICS_TAGS_SERVICE
              value: "ms-meu-microservico"
            - name: MANAGEMENT_METRICS_TAGS_ENVIRONMENT
              value: "production"
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /actuator/health
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: meu-microservico
  labels:
    app: meu-microservico
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/actuator/prometheus"
spec:
  selector:
    app: meu-microservico
  ports:
    - port: 8080
      targetPort: 8080
  type: ClusterIP
```

## 📊 Métricas Personalizadas

### 1. Contadores Customizados

```java
@Component
public class CustomMetrics {

    private final Counter customCounter;
    private final Timer customTimer;
    private final Gauge customGauge;

    public CustomMetrics(MeterRegistry meterRegistry) {
        this.customCounter = Counter.builder("custom.operations")
            .description("Número de operações customizadas")
            .tag("operation", "custom")
            .register(meterRegistry);

        this.customTimer = Timer.builder("custom.operation.duration")
            .description("Duração das operações customizadas")
            .register(meterRegistry);

        this.customGauge = Gauge.builder("custom.queue.size")
            .description("Tamanho da fila customizada")
            .register(meterRegistry, this, CustomMetrics::getQueueSize);
    }

    public void incrementCounter() {
        customCounter.increment();
    }

    public void recordTimer(Duration duration) {
        customTimer.record(duration);
    }

    private double getQueueSize() {
        // Implementar lógica para obter tamanho da fila
        return 0.0;
    }
}
```

### 2. Métricas de Negócio

```java
@Service
public class VideoUploadService {

    private final MeterRegistry meterRegistry;
    private final Counter uploadCounter;
    private final Timer uploadTimer;

    public VideoUploadService(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
        this.uploadCounter = Counter.builder("video.upload.total")
            .description("Total de uploads de vídeo")
            .register(meterRegistry);

        this.uploadTimer = Timer.builder("video.upload.duration")
            .description("Duração do upload de vídeo")
            .register(meterRegistry);
    }

    public void uploadVideo(VideoFile video) {
        Timer.Sample sample = Timer.start(meterRegistry);

        try {
            // Lógica de upload
            processVideoUpload(video);

            uploadCounter.increment(Tags.of(
                "status", "success",
                "video_type", video.getType(),
                "size_category", getSizeCategory(video.getSize())
            ));

        } catch (Exception e) {
            uploadCounter.increment(Tags.of(
                "status", "error",
                "error_type", e.getClass().getSimpleName()
            ));
            throw e;
        } finally {
            sample.stop(uploadTimer);
        }
    }

    private String getSizeCategory(long size) {
        if (size < 1024 * 1024) return "small";      // < 1MB
        if (size < 10 * 1024 * 1024) return "medium"; // < 10MB
        return "large";                              // >= 10MB
    }
}
```

## 🔍 Verificação da Integração

### 1. Verificar Métricas no Microsserviço

```bash
# Verificar endpoints do actuator
curl http://localhost:8080/actuator/health
curl http://localhost:8080/actuator/metrics
curl http://localhost:8080/actuator/prometheus

# Verificar métricas específicas
curl http://localhost:8080/actuator/metrics/jvm.memory.used
curl http://localhost:8080/actuator/metrics/http.server.requests
```

### 2. Verificar no OpenTelemetry Collector

```bash
# Verificar logs do collector
kubectl logs -n observability deployment/otel-collector

# Verificar métricas do collector
kubectl port-forward -n observability service/otel-collector 8889:8889
curl http://localhost:8889/metrics | grep otelcol_receiver_accepted
```

### 3. Verificar no Prometheus

```bash
# Verificar targets
kubectl port-forward -n observability service/prometheus 9090:9090
# Acesse http://localhost:9090/targets
```

### 4. Verificar no Grafana

```bash
# Acessar Grafana
kubectl port-forward -n observability service/grafana 3000:3000
# Acesse http://localhost:3000 e verifique os dashboards
```

## 🎯 Exemplos por Tipo de Microsserviço

### 1. Microsserviço de Upload de Vídeo

```yaml
# Configurações específicas
management:
  metrics:
    tags:
      application: video-upload-service
      service: ms-video-upload
      component: upload
```

### 2. Microsserviço de Processamento

```yaml
# Configurações específicas
management:
  metrics:
    tags:
      application: video-processing-service
      service: ms-video-processing
      component: processor
```

### 3. Microsserviço de Notificação

```yaml
# Configurações específicas
management:
  metrics:
    tags:
      application: notification-service
      service: ms-notification
      component: notifier
```

### 4. Microsserviço de Autenticação

```yaml
# Configurações específicas
management:
  metrics:
    tags:
      application: auth-service
      service: ms-auth
      component: authenticator
```

## 🚨 Troubleshooting

### Problemas Comuns

#### 1. Métricas não aparecem no Prometheus

```bash
# Verificar conectividade
kubectl exec -n observability deployment/otel-collector -- nslookup meu-microservico

# Verificar logs do collector
kubectl logs -n observability deployment/otel-collector | grep ERROR

# Verificar configuração OTLP
kubectl get configmap otel-collector-config -n observability -o yaml
```

#### 2. Microsserviço não consegue conectar ao Collector

```bash
# Verificar DNS
kubectl exec deployment/meu-microservico -- nslookup otel-collector

# Verificar serviço
kubectl get service otel-collector -n observability

# Verificar conectividade
kubectl exec deployment/meu-microservico -- curl -v http://otel-collector:4318/v1/metrics
```

#### 3. Métricas duplicadas ou incorretas

```bash
# Verificar tags
kubectl exec deployment/meu-microservico -- curl http://localhost:8080/actuator/metrics

# Verificar configuração
kubectl describe deployment meu-microservico
```

## 📈 Dashboards Personalizados

### Criar Dashboard Específico

1. **Acesse o Grafana** (http://localhost:3000)
2. **Crie novo dashboard**
3. **Configure queries** usando labels específicos:

```promql
# Métricas por serviço específico
rate(http_server_requests_total{service="ms-video-upload"}[5m])

# Métricas por aplicação
jvm_memory_used_bytes{application="video-upload-service"}

# Métricas customizadas
rate(video_upload_total[5m])
```

## 🔗 Links Úteis

- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Micrometer OTLP](https://micrometer.io/docs/registry/otlp)
- [OpenTelemetry Java](https://opentelemetry.io/docs/instrumentation/java/)
- [Prometheus Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
