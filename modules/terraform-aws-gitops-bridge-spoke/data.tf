data "aws_caller_identity" "current" {}
# get current region with data block
data "aws_region" "current" {}

data "aws_iam_session_context" "current" {
  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = data.aws_caller_identity.current.arn
}

data "aws_iam_policy_document" "irsa_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "msk_access_policy" {
  statement {
    sid    = "AllowAppsMSKClusterAccess"
    effect = "Allow"
    actions = [
      "kafka-cluster:DescribeCluster",
      "kafka-cluster:Connect",
      "kafka-cluster:AlterCluster"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowAppsMSKGroupOperations"
    effect = "Allow"
    actions = [
      "kafka-cluster:DescribeGroup",
      "kafka-cluster:AlterGroup"
    ]
    resources = ["arn:aws:kafka:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:group/*/*"]
  }

  statement {
    sid    = "AllowAppsMSKTopicsRead"
    effect = "Allow"
    actions = [
      "kafka-cluster:ReadData",
      "kafka-cluster:*Topic*"
    ]
    resources = ["arn:aws:kafka:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/*/*"]
  }
  statement {
    actions   = ["kafka-cluster:DeleteTopic"]
    effect    = "Deny"
    resources = ["*"]

  }
}




/*
data "aws_ssm_parameter" "hub_cluster" {
  count = var.gitops_deployment_type == "hub-spoke" ? 1 : 0
  #TODO: migrate to arn when using RAM
  name = "/DevSecOps/control_plane/cluster_auth"

}
*/

#data "aws_subnet" "private" {
#  for_each =  toset(coalesce(var.private_subnets_ids,[]))
#  id       = each.value
#}

data "aws_subnet" "second_private" {
  #for_each = var.use_custom_cni_conf ? toset(module.vpc.private_secondary_subnet_ids) : []
  for_each = toset(coalesce(var.private_secondary_subnet_ids, []))
  id       = each.value
}
locals {
  # Using tuple with two elements

  second_subnet_details =  length(coalesce(var.private_secondary_subnet_ids, [])) > 0  ? {
    for az, details in {
      for subnet_id in var.private_secondary_subnet_ids :
      data.aws_subnet.second_private[subnet_id].availability_zone => {
        subnetId   = subnet_id
        cidr = data.aws_subnet.second_private[subnet_id].cidr_block
        availabilityZone = data.aws_subnet.second_private[subnet_id].availability_zone
      }...
    } : az => details
  } : {}
}