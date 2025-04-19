/*
* # Module for terraform-aws-gitops-bridge-spoke deployment
*
* Terraform stack to provision a custom terraform-aws-gitops-bridge-spoke
*
*/


################################################################################
# GitOps Bridge: Bootstrap for Hub Cluster
################################################################################

module "gitops_bridge_bootstrap_hub" {
  #count  = var.gitops_deployment_type == "hub-spoke" && var.enable ? 1 : 0
  source  = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.1.0"
  # The ArgoCD remote cluster secret is deploy on hub cluster not on spoke clusters
  providers = {
    kubernetes = kubernetes.hub
  }
  install = false
   # We are not installing argocd via helm on hub cluster
  cluster = {
    cluster_name = var.cluster_name
    environment  = local.environment # argo environments
    metadata     = local.addons_metadata
    addons       = local.addons
    server       = var.cluster_endpoint
    config       = <<-EOT
      {
        "tlsClientConfig": {
          "insecure": false,
          "caData" : "${var.cluster_certificate_authority_data}"
        },
        "awsAuthConfig" : {
          "clusterName": "${var.cluster_name}",
          "roleARN": "${aws_iam_role.spoke[0].arn}"
        }
      }
    EOT
  }
  #tags = var.tags
}

################################################################################
# ArgoCD EKS Access
################################################################################
resource "aws_iam_role" "spoke" {
  count              = var.gitops_deployment_type == "hub-spoke" || var.gitops_deployment_type == "single"? 1 : 0
  name               = "${var.environment}-argocd-spoke"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy[0].json
  tags =var.tags
    lifecycle {
    create_before_destroy = true
  }
  #depends_on = [module.tm_kubernetes_infra]
}

data "aws_iam_policy_document" "assume_role_policy" {
  count              = var.gitops_deployment_type == "hub-spoke" || var.gitops_deployment_type == "single"? 1 : 0
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type = "AWS"
      identifiers = [
        #TODO: migrate to load from parameter store
        "arn:aws:iam::${var.hub_account_id}:role/eks-role-hub-control-plane",

      ]
      #data.terraform_remote_state.cluster_hub.outputs.argocd_iam_role_arn]
    }
  }
}
#############################################################################
# Access Entry for HUB access
#############################################################################
resource "aws_eks_access_entry" "hub_access" {
   count              = var.gitops_deployment_type == "hub-spoke" ? 1 : 0
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.spoke[0].arn
  user_name = "devsecops-hub"
  type = "STANDARD"
  kubernetes_groups = []
  tags = var.tags

}


resource "aws_eks_access_policy_association" "hub_access" {
   count              = var.gitops_deployment_type == "hub-spoke" ? 1 : 0
  #for_each = { for k, v in local.flattened_access_entries : "${v.entry_key}_${v.pol_key}" => v if local.create }

  access_scope {
   #namespaces = try(each.value.association_access_scope_namespaces, [])
    type       = "cluster"
  }

  cluster_name = var.cluster_name

  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn =aws_iam_role.spoke[0].arn

  depends_on = [
    aws_eks_access_entry.hub_access,
  ]
}
