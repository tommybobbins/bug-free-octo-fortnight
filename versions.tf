terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">=4.68.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
  required_version = "> 0.14"
}

