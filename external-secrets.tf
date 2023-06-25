provider "helm" {
  kubernetes {
    host     = "https://${google_container_cluster.primary.endpoint}"
    token    = data.google_client_config.default.access_token
    insecure = true
  }
}

resource "helm_release" "external-secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  timeout          = 600
  values     = [templatefile("helm/external-secrets/overrides.yaml", {
    service_account="external-secrets-k8s@${var.project}.iam.gserviceaccount.com"
    })]
  depends_on = [
    google_container_cluster.primary
  ]
}

resource "kubectl_manifest" "cluster_secretstore" {
  yaml_body = templatefile("helm/external-secrets/cluster_secretstore.yaml", {
    project = var.project,
    region  = var.region
    depends_on = [
      helm_release.external-secrets
    ]
   })
}
