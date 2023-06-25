// Configure the Google Cloud provider

variable "region" {
  description = "Google Cloud region"
  default     = "europe-west2"
}

variable "project" {
  description = "Google Cloud Project Name"
  default     = "my-project-name"
}

variable "credentials_file" {
  description = "Google Cloud Credentials json file"
  default     = "credentials.json"
}

variable "env" {
  description = "Project environment"
  default     = "dev"
}

variable "cost_centre" {
  description = "Project Cost Centre"
  default     = "costly"
}

variable "thisproject" {
  description = "Project Name"
  default     = "projectly"
}

variable "alias" {
  description = "Project Alias"
  default     = "bobbins"
}


locals {
  project_labels = {
    "env"         = var.env
    "alias"       = var.alias
    "cost_centre" = var.cost_centre
    "project"     = var.thisproject
    "gcp_project" = var.project
  }
}

variable "project_lifecycle" {
  description = "Project lifecycle (future production environment can be in development)"
  default     = "live"
}

variable "kong_min_replicas" {
  description = "Minimum number of kong pods"
  default = 1
} 

variable "kong_max_replicas" {
  description = "Maximum number of kong pods"
  default = 1
} 
