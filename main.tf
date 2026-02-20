terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    bucket = "incident-commander-tf-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ─── APIs ────────────────────────────────────────────────────────────────────

resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
  ])

  service            = each.key
  disable_on_destroy = false
}

# ─── Artifact Registry ───────────────────────────────────────────────────────

resource "google_artifact_registry_repository" "images" {
  repository_id = var.artifact_registry_repo
  format        = "DOCKER"
  location      = var.region
  description   = "Incident Commander container images"

  depends_on = [google_project_service.apis]
}

# ─── GCS bucket ──────────────────────────────────────────────────────────────

resource "google_storage_bucket" "artifacts" {
  name                        = var.gcs_bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = false

  lifecycle_rule {
    condition { age = 90 }
    action { type = "Delete" }
  }

  depends_on = [google_project_service.apis]
}

# ─── Service account: Cloud Run Job runtime ──────────────────────────────────

resource "google_service_account" "runner" {
  account_id   = var.service_account_name
  display_name = "Incident Commander Cloud Run Runner"
}

resource "google_secret_manager_secret_iam_member" "runner_secret_access" {
  secret_id = google_secret_manager_secret.openrouter_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_storage_bucket_iam_member" "runner_gcs_write" {
  bucket = google_storage_bucket.artifacts.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.runner.email}"
}

# ─── Service account: GitHub Actions CI ──────────────────────────────────────

resource "google_service_account" "ci" {
  account_id   = "incident-commander-ci"
  display_name = "Incident Commander GitHub Actions CI"
}

resource "google_storage_bucket_iam_member" "ci_terraform_state" {
  bucket = "incident-commander-tf-state"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ci.email}"
}

# Push images to Artifact Registry
resource "google_artifact_registry_repository_iam_member" "ci_ar_push" {
  repository = google_artifact_registry_repository.images.name
  location   = var.region
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.ci.email}"
}

# Create / update / run Cloud Run Jobs
resource "google_project_iam_member" "ci_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.ci.email}"
}

# Impersonate the runner SA when deploying the job
resource "google_service_account_iam_member" "ci_act_as_runner" {
  service_account_id = google_service_account.runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.ci.email}"
}

# ─── Secret Manager ──────────────────────────────────────────────────────────

resource "google_secret_manager_secret" "openrouter_key" {
  secret_id = "OPENROUTER_API_KEY"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

# NOTE: Secret value is NOT managed by Terraform. Set it once:
#   echo -n "sk-or-..." | gcloud secrets versions add OPENROUTER_API_KEY \
#     --data-file=- --project cloud-gaming-443109

# ─── Cloud Run Job ───────────────────────────────────────────────────────────

resource "google_cloud_run_v2_job" "incident_commander" {
  name     = var.cloud_run_job_name
  location = var.region

  template {
    template {
      service_account = google_service_account.runner.email

      # Dedicated Gen2 instance — no CPU throttling, no resource sharing
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

      containers {
        image = var.container_image

        resources {
          limits = {
            cpu    = var.job_cpu
            memory = var.job_memory
          }
        }

        env {
          name  = "ARTIFACTS_GCS_DIR"
          value = "gs://${google_storage_bucket.artifacts.name}/${var.gcs_artifacts_prefix}"
        }

        env {
          name = "OPENROUTER_API_KEY"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.openrouter_key.secret_id
              version = "latest"
            }
          }
        }
      }

      timeout     = "${var.job_timeout_seconds}s"
      max_retries = 0
    }
  }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.images,
    google_service_account.runner,
    google_secret_manager_secret.openrouter_key,
  ]
}
