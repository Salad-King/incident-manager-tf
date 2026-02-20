variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "cloud-gaming-443109"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "artifact_registry_repo" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "incident-commander"
}

variable "gcs_bucket_name" {
  description = "GCS bucket for RCA report artifacts"
  type        = string
  default     = "incident-commander-artifacts"
}

variable "gcs_artifacts_prefix" {
  description = "Path prefix inside the bucket for RCA reports"
  type        = string
  default     = "rca-reports"
}

variable "cloud_run_job_name" {
  description = "Cloud Run Job name"
  type        = string
  default     = "incident-commander-job"
}

variable "service_account_name" {
  description = "Service account name for the Cloud Run Job"
  type        = string
  default     = "incident-commander-runner"
}

variable "github_repo" {
  description = "GitHub repository in org/repo format for Workload Identity Federation"
  type        = string
  default     = "Salad-King/incident-manager"
}

variable "wif_pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
  default     = "github-pool"
}

variable "wif_provider_id" {
  description = "Workload Identity Provider ID"
  type        = string
  default     = "github-provider"
}

variable "container_image" {
  description = "Full container image URI for the Cloud Run Job (updated by CI)"
  type        = string
  default     = "us-central1-docker.pkg.dev/cloud-gaming-443109/incident-commander/incident-commander:latest"
}

variable "job_cpu" {
  description = "CPU allocation for the Cloud Run Job"
  type        = string
  default     = "2"
}

variable "job_memory" {
  description = "Memory allocation for the Cloud Run Job"
  type        = string
  default     = "2Gi"
}

variable "job_timeout_seconds" {
  description = "Max task execution time in seconds"
  type        = number
  default     = 600
}
