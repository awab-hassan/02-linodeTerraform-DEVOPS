terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      version = "1.29.4"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.16.1"
    }
  }
}

//Use the Linode Provider
provider "linode" {
  token = "SECURITY_TOKEN"
}

// Change the config_path according to where you installed your config.yaml file from linode kubernetes GUI. 
provider "kubernetes" {
  config_paths = [
    "PATH_OF_KUBECONFIG_FILE",
  ]
}

// Declaring all the variables that we are gonna use. 
variable "token" {}
variable "k8s_version" {}
variable "label" {}
variable "region" {}
variable "tags" {}
variable "pools" {}

// Cluster data here ( Hardcoding for now to demonstrate )
resource "linode_lke_cluster" "foobar" {
    k8s_version = "1.24"
    label = "default-lke"
    region = "us-east"
    tags = ["dev"]

    dynamic "pool" {
      for_each = var.pools
      content {
            type  = pool.value["type"]
            count = pool.value["count"]
        }
    }
}

// Integrating LKE with kubernetes and deploy nginx
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

// This is MongoDB kubernetes deployment. 
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
            container_port = "27017"
            protocol = "TCP"
          }
          env {
            name = "MONGO_INITDB_ROOT_USERNAME"
            value = "admin"
          }
          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value = "password"
          }
        }
      }
    }
  }
}

// This is the service of mongodb deployments
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

// This is the configmap of MONGODB Database you will use this in order to connect your applicaiton.
// Just refrence this in your applicaiton deployment.
resource "kubernetes_config_map_v1" "mongodb" {
  metadata {
    name = "my-config"
  }
  
  data = {
    database_url = "mongodb"
  }
}

// Enabling autoscaling
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

//Export this cluster's attributes
output "kubeconfig" {
   value = linode_lke_cluster.foobar.kubeconfig
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
