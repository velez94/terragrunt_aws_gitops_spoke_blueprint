####################################################################################
# Enable or disable stack creation
####################################################################################
variable "enable" {
  description = "Enable or disable stack creation"
  type        = bool
  default     = true
}
##################################################################################
# Stack variables
##################################################################################
variable "environment" {
  description = "The environment where this stack is deployed"
  type        = string
  default = "dev"
}
variable "vpc_id" {
  description = "VPC Id"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^vpc-[a-z0-9]{8,}$", var.vpc_id)) || var.vpc_id == ""
    error_message = "The vpc_id must be a valid VPC ID (vpc-xxxxxxxx) or an empty string."
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.cluster_name))
    error_message = "The cluster_name must consist of alphanumeric characters and hyphens only."
  }
}

variable "cluster_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.30"

  validation {
    condition     = can(regex("^\\d+\\.\\d+$", var.cluster_version))
    error_message = "The cluster_version must be in the format 'X.Y' (e.g., '1.30')."
  }
}

variable "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  type        = string

  validation {
    condition     = can(regex("^https://", var.cluster_endpoint))
    error_message = "The cluster_endpoint must start with 'https://'."
  }
}
/*
variable "cluster_platform_version" {
  description = "Platform version for the cluster"
  type        = string

  validation {
    condition     = can(regex("^eks\\.\\d+$", var.cluster_platform_version))
    error_message = "The cluster_platform_version must be in the format 'eks.X' (e.g., 'eks.5')."
  }
}
*/

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:oidc-provider/", var.oidc_provider_arn))
    error_message = "The oidc_provider_arn must be a valid ARN for an OIDC provider."
  }
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string

  validation {
    condition     = can(base64decode(var.cluster_certificate_authority_data))
    error_message = "The cluster_certificate_authority_data must be a valid base64 encoded string."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# Addons Git
variable "gitops_addons_org" {
  description = "Git repository org/user contains for addons"
  type        = string
  default     = "https://github.com/gitops-bridge-dev"
}
variable "gitops_addons_repo" {
  description = "Git repository contains for addons"
  type        = string
  default     = "gitops-bridge-argocd-control-plane-template"
}
variable "gitops_addons_revision" {
  description = "Git repository revision/branch/ref for addons"
  type        = string
  default     = "HEAD"

}
variable "gitops_addons_basepath" {
  description = "Git repository base path for addons"
  type        = string
  default     = "gitops/addons/"
}
variable "gitops_addons_path" {
  description = "Git repository path for addons"
  type        = string
  default     = "bootstrap/control-plane/addons"
}

variable "addons" {
  description = "Kubernetes addons"
  type        = any
  default = {
    enable_aws_load_balancer_controller          = true
    enable_metrics_server                        = true
    enable_external_secrets                      = true
    enable_external_dns                          = true
    enable_secrets_store_csi_driver              = true
    enable_secrets_store_csi_driver_provider_aws = true
    enable_karpenter                             = false
    enable_cluster_autoscaler                    = false
    enable_aws_node_termination_handler          = true
    enable_argo_workflows                        = false
  }
}
########################################################################################################################
# Platform GitOps Creds
########################################################################################################################
/*variable "gitops_user" {
  description = "GitOps user"
  type        = string
  default     = "gitops"
}
variable "GITOPS_PASSWORD" {
  description = "GitOps password or token"
  type        = string

}
*/
########################################################################################################################
# workloads GitOps
########################################################################################################################

variable "gitops_workloads_basepath" {
  description = "Git repository base path for workload"
  default     = ""
}
variable "gitops_workloads_path" {
  description = "Git repository path for workload"
  default     = ""
}
variable "gitops_workloads_revision" {
  description = "Git repository revision/branch/ref for workload"
  default     = "HEAD"
}
variable "gitops_workloads_repo" {
  description = "Git repository name for workload"
  default     = "gitops-apps"
}
variable "gitops_workloads_org" {
  description = "Git repository org/user contains for addons"
  type        = string
  default     = "https://github.com/gitops-bridge-dev"
}
# #######################################################################################################################
# Platform GitOps
########################################################################################################################
variable "gitops_platform_org" {
  description = "Git repository org/user contains for addons"
  type        = string
  default     = "https://github.com/gitops-bridge-dev"
}

variable "gitops_platform_basepath" {
  description = "Git repository base path for platform"
  default     = ""
}
variable "gitops_platform_path" {
  description = "Git repository path for workload"
  default     = "bootstrap"
}
variable "gitops_platform_revision" {
  description = "Git repository revision/branch/ref for workload"
  default     = "HEAD"
}
variable "gitops_platform_repo" {
  description = "Git repository name for platform"
  default     = "gitops-platform"
}

########################################################################################################################
# Conf Metadata DNS Addon
#########################################################################################################################
variable "conf_metadata" {
  description = "Metadata for the configuration"
  type = object({
    enable_karpenter_conf        = bool
    enable_system_customizations = bool

    enable_cni_custom            = bool
  })
  default = {
    enable_karpenter_conf        = false
    enable_system_customizations = false
    enable_cni_custom            = false

  }
}
# ######################################################################################################################
# External DNS Addon
########################################################################################################################
/*variable "private_route53_zone_arn" {

  description = "Private Route53 zone ARN"
  type        = list(string)
  validation {
    condition = alltrue([
      for arn in var.private_route53_zone_arn :
      can(regex("^arn:aws:route53:::hostedzone/[A-Z0-9]{1,32}$", arn))
    ]) || var.private_route53_zone_arn == []
    error_message = "Each private_route53_zone_arn must be a valid Route53 hosted zone ARN (e.g., 'arn:aws:route53:::hostedzone/Z1234567890ABC') or the list must be empty."
  }

}
variable "public_route53_zone_arn" {
  description = "Public Route53 zone ARN"
  type        = list(string)
  validation {
    condition = alltrue([
      for arn in var.public_route53_zone_arn :
      can(regex("^arn:aws:route53:::hostedzone/[A-Z0-9]{1,32}$", arn))
    ]) || var.public_route53_zone_arn == []
    error_message = "Each private_route53_zone_arn must be a valid Route53 hosted zone ARN (e.g., 'arn:aws:route53:::hostedzone/Z1234567890ABC') or the list must be empty."
  }
}

variable "external_dns_domain_filters" {
  type        = list(string)
  description = "External domains filters"
  default     = []
}

*/
################################################################################
# Cluster Autoscaler
################################################################################

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster autoscaler add-on"
  type        = bool
  default     = false
}

variable "cluster_autoscaler" {
  description = "Cluster Autoscaler add-on configuration values"
  type        = any
  default     = {}
}
################################################################################
# AWS Node Termination Handler
################################################################################

variable "eks_auto_scaling_groups_arns" {
  description = "List of EKS Auto Scaling Groups ARNs"
  type        = list(string)
  default     = []
}

############################################################################################
# GitOps type architecture
#############################################################################################
variable "gitops_deployment_type" {
  description = "GitOps type architecture deployment. hub-spoke, single"
  type        = string
  default     = "hub-spoke"
  validation {
    condition     = can(regex("^(hub-spoke|single)$", var.gitops_deployment_type))
    error_message = "The gitops_type must be 'hub-spoke' or 'single'."
  }
}

#variable "argocd_iam_role_arn" {
#  description = "The ARN of the IAM role for Argo CD"
#  type        = string

#}
variable "hub_account_id" {
  description = "Argo CD hub account ID"
  type        = string
  default     = ""
}
variable "shared_hub_secret_suffix" {
  type        = string
  description = "suffix for shared secret"
  default     = "LQXNDi"
}
############################################################################################
# cni metadata values
############################################################################################
variable "subnet_details" {
  description = "Map of subnet details"
  type = map(list(object({
    cidr     = string
    subnetId = string
    availabilityZone = string

  })))
  default = {}

}


#######################################################################################################################
# secondary subnets variables for cni
#######################################################################################################################
variable "use_secondary_subnets" {
  description = "Use secondary subnets for private and public subnets"
  type        = bool
  default     = false
}

variable "pods_security_groups" {
  description = "Pods security groups"
  type        = list(string)
  default     = []
  validation {
    condition     =  length(var.pods_security_groups) == 0 ? true : alltrue([for sg in var.pods_security_groups : can(regex("^sg-[a-z0-9]{17}$", sg))])
    error_message = "Each pods_security_group value must be a valid security group ID."
  }
}
variable "azs" {
  description = "A list of availability zones specified as argument to this module"
  type        = list(string)
  default     = []
}

variable "private_secondary_subnet_ids" {
  description = "Private secondary subnet IDs"
  type        = list(string)
  default     = []
  validation {
    condition     = var.private_secondary_subnet_ids == [] || length(coalesce(var.private_secondary_subnet_ids, [])) == 0 ? true : length(var.private_secondary_subnet_ids) >= 2
    error_message = "The private_secondary_subnets_ids value must contain at least two subnet IDs."
  }
}

variable "account_name_prefix" {
  description = "Account name prefix"
  type        = string
  default     = ""
}

#######################################################################################################################
# Permissions boundary
#######################################################################################################################
variable "permissions_boundary" {
  description = "Permissions boundary policy name"
  type        = string
  default     = null
}
variable "eks_kms_arn" {
  description = "EKS KMS ARN"
  type        = string
  default     = null
}
variable "vpc_cni_conf_mode" {
  description = "VPC CNI mode, use custom_cfg for secondary subnets and default_cfg for delegation prefix"
  type        = string
  default     = "custom_cfg"
  # add validation allowed values custom_cfg, default_cfg
  validation {
    condition     = contains(["custom_cfg", "default_cfg"], var.vpc_cni_conf_mode)
    error_message = "Allowed values for vpc_cni_conf_mode are custom_cfg, default_cfg."
  }
}