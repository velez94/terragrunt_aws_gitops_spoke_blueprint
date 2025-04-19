output "hub_conf" {
  value       = module.gitops_bridge_bootstrap_hub
  description = "EKS Gitops Boostrap"
  sensitive = true
}

