
resource "kubernetes_namespace" "kong" {
  metadata {
    name = "kong"
  }
 depends_on = [
   google_container_cluster.primary
 ]
}

resource "google_compute_address" "kong_ip_address" {
  name         = "kong-vip-address"
  network_tier = "PREMIUM"
}

resource "kubectl_manifest" "tls_secret" {
  yaml_body = file("${path.module}/helm/kong/kong-tls-cert.yaml")
  depends_on = [
    kubernetes_namespace.kong,
    kubectl_manifest.cluster_secretstore,
    time_sleep.wait_for_secretstore
  ]
}

resource "helm_release" "kong" {
  name       = "kong"
  repository = "https://charts.konghq.com"
  chart      = "kong"
  namespace  = "kong"
  create_namespace = "true"
  timeout    = 600
  values = [
    "${templatefile("helm/kong/values.yaml", {
      kong_min_replicas      = var.kong_min_replicas
      kong_max_replicas      = var.kong_max_replicas
      kong_global_ip_address = google_compute_address.kong_ip_address.address
    })}"
  ]
  depends_on = [
    kubectl_manifest.tls_secret // only run the helm chart once the license secret is in place
  ]
}

resource "time_sleep" "wait_for_kong_lb" {
  depends_on = [
    helm_release.kong
  ]
  create_duration = "60s" // wait 60 seconds after helm chart completion for loadbalancer to come up
}

resource "time_sleep" "wait_for_secretstore" {
  depends_on = [
    kubectl_manifest.cluster_secretstore
  ]
  create_duration = "120s" // wait 60 seconds after helm chart completion for loadbalancer to come up
}
