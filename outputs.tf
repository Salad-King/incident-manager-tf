output "artifact_registry_url" {
  description = "Base URL for pushing images to Artifact Registry"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}"
}

output "gcs_artifacts_dir" {
  description = "Full GCS path for RCA report uploads"
  value       = "gs://${google_storage_bucket.artifacts.name}/${var.gcs_artifacts_prefix}"
}

output "cloud_run_job_name" {
  description = "Cloud Run Job name"
  value       = google_cloud_run_v2_job.incident_commander.name
}

output "runner_service_account" {
  description = "Service account email used by the Cloud Run Job"
  value       = google_service_account.runner.email
}

output "wif_provider" {
  description = "Full WIF provider resource name — use as WIF_PROVIDER GitHub secret"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "wif_service_account" {
  description = "Service account email for WIF — use as WIF_SERVICE_ACCOUNT and CLOUD_RUN_SA GitHub secrets"
  value       = google_service_account.runner.email
}

output "artifacts_gcs_dir" {
  description = "ARTIFACTS_GCS_DIR value — use as ARTIFACTS_GCS_DIR GitHub secret"
  value       = "gs://${google_storage_bucket.artifacts.name}/${var.gcs_artifacts_prefix}"
}
