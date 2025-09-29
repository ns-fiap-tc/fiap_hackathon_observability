# Namespace para observabilidade
resource "kubernetes_namespace" "observability" {
  metadata {
    name = "observability"
    labels = {
      name = "observability"
    }
  }
}

# ConfigMap para OpenTelemetry Collector
resource "kubernetes_config_map" "otel_collector_config" {
  metadata {
    name      = "otel-collector-config"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  data = {
    "otel-collector-config.yaml" = file("${path.module}/monitoring/otel-collector-config.yaml")
  }
}

# Deployment do OpenTelemetry Collector
resource "kubernetes_deployment" "otel_collector" {
  metadata {
    name      = "otel-collector"
    namespace = kubernetes_namespace.observability.metadata[0].name
    labels = {
      app = "otel-collector"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "otel-collector"
      }
    }

    template {
      metadata {
        labels = {
          app = "otel-collector"
        }
      }

      spec {
        container {
          name  = "otel-collector"
          image = "otel/opentelemetry-collector-contrib:0.88.0"

          args = ["--config=/etc/otel-collector-config.yaml"]

          port {
            container_port = 4317
            name           = "otlp-grpc"
          }

          port {
            container_port = 4318
            name           = "otlp-http"
          }

          port {
            container_port = 8889
            name           = "prometheus"
          }

          volume_mount {
            name       = "otel-collector-config"
            mount_path = "/etc/otel-collector-config.yaml"
            sub_path   = "otel-collector-config.yaml"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "otel-collector-config"
          config_map {
            name = kubernetes_config_map.otel_collector_config.metadata[0].name
          }
        }
      }
    }
  }
}

# Service para OpenTelemetry Collector
resource "kubernetes_service" "otel_collector" {
  metadata {
    name      = "otel-collector"
    namespace = kubernetes_namespace.observability.metadata[0].name
    labels = {
      app = "otel-collector"
    }
  }

  spec {
    selector = {
      app = "otel-collector"
    }

    port {
      name        = "otlp-grpc"
      port        = 4317
      target_port = 4317
      protocol    = "TCP"
    }

    port {
      name        = "otlp-http"
      port        = 4318
      target_port = 4318
      protocol    = "TCP"
    }

    port {
      name        = "prometheus"
      port        = 8889
      target_port = 8889
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# ConfigMap para Prometheus
resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  data = {
    "prometheus.yml" = file("${path.module}/monitoring/prometheus.yml")
  }
}

# Deployment do Prometheus
resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.observability.metadata[0].name
    labels = {
      app = "prometheus"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }

      spec {
        container {
          name  = "prometheus"
          image = "prom/prometheus:v2.45.0"

          args = [
            "--config.file=/etc/prometheus/prometheus.yml",
            "--storage.tsdb.path=/prometheus/",
            "--web.console.libraries=/etc/prometheus/console_libraries",
            "--web.console.templates=/etc/prometheus/consoles",
            "--storage.tsdb.retention.time=200h",
            "--web.enable-lifecycle"
          ]

          port {
            container_port = 9090
            name           = "web"
          }

          volume_mount {
            name       = "prometheus-config"
            mount_path = "/etc/prometheus"
          }

          volume_mount {
            name       = "prometheus-storage"
            mount_path = "/prometheus"
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
          }
        }

        volume {
          name = "prometheus-config"
          config_map {
            name = kubernetes_config_map.prometheus_config.metadata[0].name
          }
        }

        volume {
          name = "prometheus-storage"
          empty_dir {}
        }
      }
    }
  }
}

# Service para Prometheus
resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.observability.metadata[0].name
    labels = {
      app = "prometheus"
    }
  }

  spec {
    selector = {
      app = "prometheus"
    }

    port {
      name        = "web"
      port        = 9090
      target_port = 9090
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# ConfigMap para datasources do Grafana
resource "kubernetes_config_map" "grafana_datasources" {
  metadata {
    name      = "grafana-datasources"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  data = {
    "prometheus.yaml" = file("${path.module}/../grafana/provisioning/datasources/prometheus.yaml")
  }
}

# ConfigMap para configuração de dashboards do Grafana
resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "grafana-dashboards"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  data = {
    "dashboard.yaml" = file("${path.module}/../grafana/provisioning/dashboards/dashboard.yaml")
  }
}

# ConfigMap para arquivos de dashboard do Grafana
resource "kubernetes_config_map" "grafana_dashboard_files" {
  metadata {
    name      = "grafana-dashboard-files"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  data = {
    "microservices-overview.json" = file("${path.module}/../grafana/dashboards/microservices-overview.json")
    "otel-collector-monitoring.json" = file("${path.module}/../grafana/dashboards/otel-collector-monitoring.json")
  }
}

# Deployment do Grafana
resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.observability.metadata[0].name
    labels = {
      app = "grafana"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "grafana"
      }
    }

    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }

      spec {
        container {
          name  = "grafana"
          image = "grafana/grafana:10.1.0"

          port {
            container_port = 3000
            name           = "http"
          }

          env {
            name  = "GF_SECURITY_ADMIN_PASSWORD"
            value = "admin"
          }

          env {
            name  = "GF_USERS_ALLOW_SIGN_UP"
            value = "false"
          }

          volume_mount {
            name       = "grafana-storage"
            mount_path = "/var/lib/grafana"
          }

          volume_mount {
            name       = "grafana-datasources"
            mount_path = "/etc/grafana/provisioning/datasources"
          }

          volume_mount {
            name       = "grafana-dashboards"
            mount_path = "/etc/grafana/provisioning/dashboards"
          }

          volume_mount {
            name       = "grafana-dashboard-files"
            mount_path = "/var/lib/grafana/dashboards"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "grafana-storage"
          empty_dir {}
        }

        volume {
          name = "grafana-datasources"
          config_map {
            name = kubernetes_config_map.grafana_datasources.metadata[0].name
          }
        }

        volume {
          name = "grafana-dashboards"
          config_map {
            name = kubernetes_config_map.grafana_dashboards.metadata[0].name
          }
        }

        volume {
          name = "grafana-dashboard-files"
          config_map {
            name = kubernetes_config_map.grafana_dashboard_files.metadata[0].name
          }
        }
      }
    }
  }
}

# Service para Grafana
resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.observability.metadata[0].name
    labels = {
      app = "grafana"
    }
  }

  spec {
    selector = {
      app = "grafana"
    }

    port {
      name        = "http"
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# ServiceAccount para Prometheus (para acessar métricas do Kubernetes)
resource "kubernetes_service_account" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }
}

# ClusterRole para Prometheus
resource "kubernetes_cluster_role" "prometheus" {
  metadata {
    name = "prometheus"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }
}

# ClusterRoleBinding para Prometheus
resource "kubernetes_cluster_role_binding" "prometheus" {
  metadata {
    name = "prometheus"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.prometheus.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.prometheus.metadata[0].name
    namespace = kubernetes_namespace.observability.metadata[0].name
  }
}
