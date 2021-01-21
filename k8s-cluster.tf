locals {
  k8s_services = [
    "cloudapis.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dataflow.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "replicapool.googleapis.com",
    "replicapoolupdater.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
  ]
}

resource "google_project_service" "k8s_cluster" {
  count                      = length(local.k8s_services)
  service                    = local.k8s_services[count.index]
  disable_dependent_services = true
}

resource "google_container_cluster" "circleci_cluster" {
  name     = "circleci-cluster"
  location = "us-west1-a"

  # Kubernetes Version
  min_master_version = "1.17.13-gke.2600"

  # We can't create a cluster with no node pool defined, but we want to use
  # a separately managed node pool. For that, we create the smallest possible
  # default node pool and immediately delete it.
  # This is the recommended way to manage node pools with Terraform.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  depends_on = [
    google_project_service.k8s_cluster
  ]
}

resource "google_container_node_pool" "circleci_cluster_primary" {
  name     = "primary"
  location = google_container_cluster.circleci_cluster.location
  cluster  = google_container_cluster.circleci_cluster.name

  node_count = 1

  node_config {
    machine_type = "e2-standard-2"

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
}