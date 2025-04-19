locals {
  workspace = get_env("TF_VAR_env", "dev")
  pipeline = "false"
  hub_account_id    = "105171185823"
}
generate "k8s_helm_provider" {
  path      = "k8s_helm_provider.tf"
  if_exists = "overwrite"
  contents = <<EOF
################################################################################
# Kubernetes Access for Spoke Cluster
################################################################################

# First, define the parameter store data source
data "aws_ssm_parameter" "hub_cluster_config" {
  count = 1
  with_decryption = true
  name  = "arn:aws:ssm:us-east-2:${local.hub_account_id}:parameter/control_plane/${local.workspace}/credentials"
 #"/control_plane/${local.workspace}/credentials"  # Adjust the parameter path as needed
}

provider "kubernetes" {
  host = try(jsondecode(data.aws_ssm_parameter.hub_cluster_config[0].value).cluster_endpoint, var.cluster_endpoint)
  cluster_ca_certificate = try(base64decode(jsondecode(data.aws_ssm_parameter.hub_cluster_config[0].value).cluster_certificate_authority_data), var.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      try(jsondecode(data.aws_ssm_parameter.hub_cluster_config[0].value).cluster_name, var.cluster_name),
      "--region",
      try(jsondecode(data.aws_ssm_parameter.hub_cluster_config[0].value).cluster_region, data.aws_region.current.name),
      "--profile",
      var.profile["${local.workspace}"]["profile"]
    ]
  }
  alias = "hub"
}

EOF
}

