# Simple GKE autopilot cluster:
resource "google_container_cluster" "demo" {
  name     = "gke-demo-${var.resource_suffix}"
  location = var.location

  enable_autopilot    = true
  project             = var.project_id
  deletion_protection = false
}

# Retrieve an access token as the Terraform runner and setup providers
data "google_client_config" "provider" {}

provider "kubectl" {
  host = "https://${google_container_cluster.demo.endpoint}"
  cluster_ca_certificate = base64decode(
    google_container_cluster.demo.master_auth[0].cluster_ca_certificate,
  )
  token            = data.google_client_config.provider.access_token
  load_config_file = false
}

provider "kubernetes" {
  host  = "https://${google_container_cluster.demo.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.demo.master_auth[0].cluster_ca_certificate,
  )
}

provider "helm" {
  kubernetes {
    host  = "https://${google_container_cluster.demo.endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(
      google_container_cluster.demo.master_auth[0].cluster_ca_certificate,
    )
  }
}

# Deploy ArgoCD with Helm and ignore it for future changes
resource "helm_release" "argocd" {
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  verify           = false
  version          = var.argocd_version
  wait             = false

  depends_on = [
    google_container_cluster.demo
  ]

  lifecycle {
    ignore_changes = all # Just bootstrap & forget and let ArgoCD do it's job.
  }
}

# Create a Kubernetes secret for ArgoCD repo credentials
resource "kubernetes_secret" "argocd_repo_creds" {
  metadata {
    name      = "git-creds"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    url      = var.git_url
    username = "git"
    password = var.git_pat
  }

  depends_on = [
    helm_release.argocd
  ]
}

# Bootstrap ArgoCD apps and projects
resource "kubectl_manifest" "argocd_apps" {
  yaml_body = templatefile("${path.module}/data/argocd-apps.yaml.tfpl", {
    cluster_name       = google_container_cluster.demo.name
    git_repository_url = var.git_url
  })

  depends_on = [
    helm_release.argocd
  ]
}

resource "kubectl_manifest" "argocd_projects" {
  yaml_body = templatefile("${path.module}/data/argocd-projects.yaml.tfpl", {
    cluster_name       = google_container_cluster.demo.name
    git_repository_url = var.git_url
  })

  depends_on = [
    helm_release.argocd
  ]
}
