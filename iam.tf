resource "google_service_account" "k8s" {
  project = var.project
  account_id = "external-secrets-k8s"
}

resource "google_project_iam_member" "this" {
  project = var.project
#  role   = "roles/pubsub.admin"
  role   = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.k8s.email}"
}

# The creation of the binding was failing due to the nodes not being found.
# This 5 seconds sleeps fixes the issue.
resource "time_sleep" "wait_5_seconds" {
  depends_on = [google_container_cluster.primary]
  create_duration = "5s"
}

resource "google_service_account_iam_binding" "k8s" {
  depends_on = [time_sleep.wait_5_seconds]
  service_account_id = google_service_account.k8s.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project}.svc.id.goog[external-secrets/external-secrets]",
  ]
}
