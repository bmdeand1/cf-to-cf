provider "google" {
  project = var.gcp_project_id
  region  = var.region
}

# Bucket to store Cloud Functions code
resource "google_storage_bucket" "cf-bucket" {
  name                        = "cr-cf-demo-bucket"
  location                    = "EU"
  uniform_bucket_level_access = true
}

# Invokee Function
data "archive_file" "invokee_function_artifact" {
  type        = "zip"
  output_path = "${path.module}/functions/fun_two/cf-two-code.zip"

  source {
    content  = file("${path.module}/functions/fun_two/main.py")
    filename = "main.py"
  }

  source {
    content  = file("${path.module}/functions/fun_two/requirements.txt")
    filename = "requirements.txt"
  }
}

resource "google_storage_bucket_object" "cf-two-code" {
  name   = "cf-two-code.zip"
  bucket = google_storage_bucket.cf-bucket.name
  source = data.archive_file.invokee_function_artifact.output_path
}

resource "google_cloudfunctions2_function" "cf-two" {
  name        = "cf-two"
  location    = "europe-west2"
  description = "Invokee Function"

  build_config {
    runtime     = "python310"
    entry_point = "hello_http" # Set the entry point 
    source {
      storage_source {
        bucket = google_storage_bucket.cf-bucket.name
        object = google_storage_bucket_object.cf-two-code.name
      }
    }
  }

  service_config {
    max_instance_count = 4
    available_memory   = "256M"
    min_instance_count = 2
    timeout_seconds    = 60
  }
}

# Invoker Function "cf-one"
data "archive_file" "invoker_function_artifact" {
  type        = "zip"
  output_path = "${path.module}/functions/fun_one/cf-one-code.zip"

  source {
    content  = templatefile("${path.module}/functions/fun_two/main.py", { invokee_url = google_cloudfunctions2_function.cf-two.service_config[0].uri })
    filename = "main.py"
  }

  source {
    content  = file("${path.module}/functions/fun_one/requirements.txt")
    filename = "requirements.txt"
  }
}

resource "google_storage_bucket_object" "cf-one-code" {
  name   = "cf-one-code.zip"
  bucket = google_storage_bucket.cf-bucket.name
  source = data.archive_file.invoker_function_artifact.output_path
}

resource "google_service_account" "function_service_account" {
  account_id   = "function-service-account"
  display_name = "Function Service Account"
}

resource "google_project_iam_member" "run_invoker_role" {
  project = var.gcp_project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.function_service_account.email}"
}

resource "google_project_iam_member" "computer_admin_role" {
  project = var.gcp_project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.function_service_account.email}"
}

resource "google_cloudfunctions2_function" "cf-one" {
  name        = "cf-one"
  location    = "europe-west2"
  description = "Invoker Function"

  build_config {
    runtime     = "python310"
    entry_point = "hello_http"
    source {
      storage_source {
        bucket = google_storage_bucket.cf-bucket.name
        object = google_storage_bucket_object.cf-one-code.name
      }
    }
  }

  service_config {
    max_instance_count    = 4
    available_memory      = "256M"
    min_instance_count    = 2
    timeout_seconds       = 60
    service_account_email = google_service_account.function_service_account.email
  }
}

resource "google_cloud_run_service_iam_binding" "allow_unauthenticated" {
  location = google_cloudfunctions2_function.cf-one.location
  service  = google_cloudfunctions2_function.cf-one.name
  role     = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}
