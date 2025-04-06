variable "project_id" {
  description = "The project ID to deploy the resources"
  type        = string
}

variable "resource_suffix" {
  description = "Suffix for the resources"
  type        = string
}

variable "location" {
  description = "The location for the resources"
  type        = string
}

variable "git_url" {
  description = "Git URL for the repository"
  type        = string
}

variable "git_pat" {
  description = "Git Personal Access Token"
  type        = string
}

variable "argocd_version" {
  description = "Version of ArgoCD to deploy"
  type        = string 
}