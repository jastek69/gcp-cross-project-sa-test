
terraform {
  backend "gcs" {
    bucket      = "taaopsfirstterraformbucket"
    prefix      = "terraform/state092125"
    credentials = "taaops-e9943412868a.json"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.36.0"
    }
  }
}
