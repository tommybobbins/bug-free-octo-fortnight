variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}

resource "google_service_account" "k8s-default" {
  account_id   = "service-account-id"
  display_name = "k8s Service Account"
}


# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project}-gke"
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  #remove_default_node_pool = true
  initial_node_count       = 0
  #  node_locations = [
  #    "${var.region}-d",
  #  ]
  enable_autopilot = true
  network          = google_compute_network.vpc.name
  subnetwork       = google_compute_subnetwork.subnet.name

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.96.0.0/14"
    services_ipv4_cidr_block = "10.192.0.0/16"
  }
#  node_config {
#    service_account = google_service_account.k8s-default.email
#    oauth_scopes = [
#      "https://www.googleapis.com/auth/cloud-platform"
#    ]
#  }
}

# Separately Managed Node Pool
#resource "google_container_node_pool" "primary_nodes" {
#  name       = "${google_container_cluster.primary.name}-node-pool"
#  location   = var.region
#  cluster    = google_container_cluster.primary.name
#  node_count = var.gke_num_nodes
#
#  node_config {
#    oauth_scopes = [
#      "https://www.googleapis.com/auth/logging.write",
#      "https://www.googleapis.com/auth/monitoring",
#      "https://www.googleapis.com/auth/devstorage.read_only",
#      "https://www.googleapis.com/auth/cloud-platform",
#    ]
#
#    labels = {
#      env = var.project_id
#    }
#
#    # preemptible  = true
#    machine_type = "n1-standard-1"
#    tags         = ["gke-node", "${var.project_id}-gke"]
#    metadata = {
#      disable-legacy-endpoints = "true"
#    }
#  }
#}

data "google_client_config" "default" {
  depends_on = [google_container_cluster.primary]
}

data "google_container_cluster" "primary" {
  name     = "${var.project}-gke"
  location = "${var.region}"
  depends_on = [google_container_cluster.primary]
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

