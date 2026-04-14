terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "1.29.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.16.1"
    }
  }
}

provider "linode" {
  token = var.token
}

# NOTE: Two-step deployment required.
# Step 1: Comment out everything below the linode_lke_cluster resource and run:
#   terraform apply
# Then export the kubeconfig:
#   terraform output -raw kubeconfig | base64 -d > kubeconfig.yaml
# Step 2: Set kubeconfig_path to that file, uncomment everything, then run:
#   terraform apply
provider "kubernetes" {
  config_paths = [var.kubeconfig_path]
}

# LKE Cluster
resource "linode_lke_cluster" "foobar" {
  k8s_version = "1.24"
  label       = "default-lke"
  region      = "us-east"
  tags        = ["dev"]

  dynamic "pool" {
    for_each = var.pools
    content {
      type  = pool.value["type"]
      count = pool.value["count"]
    }
  }
}

# Kubernetes Secret for MongoDB credentials
resource "kubernetes_secret" "mongodb_credentials" {
  metadata {
    name      = "mongodb-secret"
    namespace = "default"
  }

  data = {
    mongo-root-username = var.mongo_root_username
    mongo-root-password = var.mongo_root_password
  }

  type = "Opaque"
}

# Apache Deployment
resource "kubernetes_deployment" "apache-server" {
  metadata {
    name = "apache-server"
    labels = {
      test = "apache-server"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        test = "apache-server"
      }
    }

    template {
      metadata {
        labels = {
          test = "apache-server"
        }
      }
      spec {
        container {
          image = "httpd"
          name  = "apache-server"
          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

# Apache Service
resource "kubernetes_service" "apache" {
  metadata {
    name      = "apache-server"
    namespace = "default"
  }
  spec {
    selector = {
      test = "apache-server"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

# MongoDB Deployment — credentials pulled from Secret
resource "kubernetes_deployment" "mongodb" {
  metadata {
    name = "mongodb"
    labels = {
      test = "mongodb"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        test = "mongodb"
      }
    }

    template {
      metadata {
        labels = {
          test = "mongodb"
        }
      }
      spec {
        container {
          image = "mongo"
          name  = "mongodb"
          port {
            container_port = 27017
            protocol       = "TCP"
          }
          env {
            name = "MONGO_INITDB_ROOT_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongodb_credentials.metadata[0].name
                key  = "mongo-root-username"
              }
            }
          }
          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongodb_credentials.metadata[0].name
                key  = "mongo-root-password"
              }
            }
          }
        }
      }
    }
  }
}

# MongoDB Service
resource "kubernetes_service" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = "default"
    labels = {
      app     = "mongodb"
      release = "mongodb"
    }
    annotations = {
      "service.alpha.kubernetes.io/tolerate-unready-endpoints" = "true"
    }
  }

  spec {
    port {
      name = "mongodb"
      port = 27017
    }
    selector = {
      app     = "mongodb"
      release = "mongodb"
    }
  }
}

# ConfigMap for MongoDB connection URL
resource "kubernetes_config_map_v1" "mongodb" {
  metadata {
    name = "my-config"
  }
  data = {
    database_url = "mongodb"
  }
}

# HPA for Apache — latency-based External metric
resource "kubernetes_horizontal_pod_autoscaler" "apache_autoscaling" {
  metadata {
    name = "apache-server-hpa"
  }

  spec {
    min_replicas = 1
    max_replicas = 10

    scale_target_ref {
      kind = "Deployment"
      name = "apache-server"
    }

    metric {
      type = "External"
      external {
        metric {
          name = "latency"
          selector {
            match_labels = {
              lb_name = "apache-server"
            }
          }
        }
        target {
          type  = "Value"
          value = "20"
        }
      }
    }
  }
}

# Outputs
output "kubeconfig" {
  value     = linode_lke_cluster.foobar.kubeconfig
  sensitive = true
}

output "api_endpoints" {
  value = linode_lke_cluster.foobar.api_endpoints
}

output "status" {
  value = linode_lke_cluster.foobar.status
}

output "id" {
  value = linode_lke_cluster.foobar.id
}

output "pool" {
  value = linode_lke_cluster.foobar.pool
}
