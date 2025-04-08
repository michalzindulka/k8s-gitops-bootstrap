# k8s-gitops-bootstrap

## About
This repository contains source code for example how to do GKE GitOps bootstraping easy and efficiently. Articles using this repo were posted on following URL's:
- [medium]()
- [linkedin]()

## How to
Before you begin, you need to have a PAT doken for GitHub with 'read' permissions to the repository.

**define tfvars**
Update tfvars for your needs. The 'git_pat' secret better to inject using ENV variable
```
export TF_VAR_git_pat=github_pat_12345
```

**apply terraform**
```
terraform apply
```

**check in argocd**
```
# Get ArgoCD password:
k get secret -n argocd argocd-initial-admin-secret --template={{.data.password}} | base64 -D

# Port forward ArgoCD:
k port-forward service/argocd-server 8080:80 -n argocd

# Go to localhost:8080 and verify apps in ArgoCD
```