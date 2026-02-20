output "artifact_registry_url" {
  description = "Base URL for pushing images to Artifact Registry"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}"
}

output "gcs_artifacts_dir" {
  description = "Full GCS path for RCA report uploads — use as ARTIFACTS_GCS_DIR GitHub secret"
  value       = "gs://${google_storage_bucket.artifacts.name}/${var.gcs_artifacts_prefix}"
}

output "cloud_run_job_name" {
  description = "Cloud Run Job name"
  value       = google_cloud_run_v2_job.incident_commander.name
}

output "runner_service_account" {
  description = "Service account email used by the Cloud Run Job at runtime"
  value       = google_service_account.runner.email
}

output "ci_service_account" {
  description = "CI service account email — create and download a key for GCP_SA_KEY GitHub secret"
  value       = google_service_account.ci.email
}
