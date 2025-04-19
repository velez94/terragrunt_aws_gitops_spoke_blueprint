locals {
  # argo cd locals values
  environment = var.environment
  #argocd_apps = {
  #  addons = file("${path.module}/bootstrap/addons.yaml")
  #  platform = file("${path.module}/bootstrap/platform.yaml")
    #workloads = file("${path.module}/bootstrap/workloads.yaml")
 # }


  # repository connection setup for cluster addons using gitops approach

  # Update with the git ssh key to be used by ArgoCD
  gitops_addons_org      = var.gitops_addons_org
  gitops_addons_url      = "${var.gitops_addons_org}/${var.gitops_addons_repo}"
  gitops_addons_basepath = var.gitops_addons_basepath
  gitops_addons_path     = var.gitops_addons_path
  gitops_addons_revision = var.gitops_addons_revision

  gitops_platform_url      = "${var.gitops_platform_org}/${var.gitops_addons_repo}"
  gitops_platform_basepath = var.gitops_platform_basepath
  gitops_platform_path     = var.gitops_platform_path
  gitops_platform_revision = var.gitops_platform_revision


  gitops_workloads_url      = "${var.gitops_workloads_org}/${var.gitops_workloads_repo}"
  gitops_workloads_basepath = var.gitops_workloads_basepath
  gitops_workloads_path     = var.gitops_workloads_path
  gitops_workloads_revision = var.gitops_workloads_revision

  oss_addons = {
    enable_metrics_server = try(var.addons.enable_metrics_server, false)
    enable_secrets_store_csi_driver = try(var.addons.enable_secrets_store_csi_driver, false)
    enable_argo_workflows = try(var.addons.enable_argo_workflows, false)
    enable_argo_events = try(var.addons.enable_argo_events, false)


  }
  aws_addons = {
    enable_aws_load_balancer_controller = try(var.addons.enable_aws_load_balancer_controller, false)
    enable_external_secrets = try(var.addons.enable_external_secrets, false)
    enable_metrics_server = try(var.addons.enable_metrics_server, false)
    enable_external_dns = try(var.addons.enable_external_dns, false)
    enable_secrets_store_csi_driver_provider_aws = try(var.addons.enable_secrets_store_csi_driver_provider_aws, false)
    enable_karpenter = try(var.addons.enable_karpenter, false)
    enable_cluster_autoscaler = try(var.addons.enable_cluster_autoscaler, false)
    enable_aws_node_termination_handler = try(var.addons.enable_aws_node_termination_handler, false)
  }
  conf_metadata = var.conf_metadata

  cni_custom = jsonencode({
    subnet-config = local.second_subnet_details #var.subnet_details,
    security-groups = var.pods_security_groups
  })
  add_metadata = {
    #project               = var.project
      cni_custom            = local.conf_metadata.enable_cni_custom ? local.cni_custom : ""



  }
  addons_metadata = merge(
    #try(module.eks_blueprints_addons[0].gitops_metadata, {}),
    local.add_metadata,
    {
      aws_cluster_name = var.cluster_name
      aws_region       = data.aws_region.current.name
      aws_account_id   = data.aws_caller_identity.current.account_id
      aws_account_name = "${var.account_name_prefix}${upper(var.environment)}"
      aws_vpc_id       = var.vpc_id
    },
    {
      addons_repo_url      = local.gitops_addons_url
      addons_repo_basepath = local.gitops_addons_basepath
      addons_repo_path     = local.gitops_addons_path
      addons_repo_revision = local.gitops_addons_revision

    },
    {
      platform_repo_url      = local.gitops_platform_url
      platform_repo_basepath = local.gitops_platform_basepath
      platform_repo_path     = local.gitops_platform_path
      platform_repo_revision = local.gitops_platform_revision
    },
    {
      workloads_repo_url      = local.gitops_workloads_url
      workloads_repo_basepath = local.gitops_workloads_basepath
      workload_repo_path      = local.gitops_workloads_path
      workloads_repo_revision = local.gitops_workloads_revision
    }
  )


  addons = merge(
    local.aws_addons, local.oss_addons, local.conf_metadata,
    { kubernetes_version = var.cluster_version },
    { aws_cluster_name = var.cluster_name }
  )


 # external_dns_route53_zone_arns = concat(var.public_route53_zone_arn, var.private_route53_zone_arn)
  cluster_vpc_cni_addon = {
     eks-pod-identity-agent = {
      most_recent = true
    }
    vpc-cni = var.vpc_cni_conf_mode == "custom_cfg" ? {
      before_compute = true
      most_recent    = true
      resolve_conflicts          = "PRESERVE"
      timeouts = {
        create = "30m"
        delete = "20m"
         update = "30m"
      }
      configuration_values = jsonencode({
        env = {
          AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
          AWS_VPC_K8S_CNI_LOGLEVEL           = "DEBUG"
          ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
          ENABLE_POD_ENI = "true"
          # Enable prefix delegation for better IP management
          "ENABLE_PREFIX_DELEGATION"         = "true"
          "WARM_PREFIX_TARGET"               = "1"


        }
      }
      )
    } : {
      before_compute = true
      most_recent    = true
      resolve_conflicts          = "PRESERVE"
      timeouts = {
        create = "30m"
        delete = "20m"
         update = "30m"
      }
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
          WARM_IP_TARGET           = "10"
          WARM_ENI_TARGET          = "2"


        }
      }
      )
    }


  }
  cluster_addons = {


    kube-proxy = {
      most_recent = true
    }

    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        computeType = "Fargate"
        # Ensure that the we fully utilize the minimum amount of resources that are supplied by
        # Fargate https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html
        # Fargate adds 256 MB to each pod's memory reservation for the required Kubernetes
        # components (kubelet, kube-proxy, and containerd). Fargate rounds up to the following
        # compute configuration that most closely matches the sum of vCPU and memory requests in
        # order to ensure pods always have the resources that they need to run.
        resources = {
          limits = {
            cpu    = "0.25"
            # We are targeting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "256M"
          }
          requests = {
            cpu    = "0.25"
            # We are targeting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "256M"
          }
        }
      })
    }

    #"aws-ebs-csi-driver" = {
    #  "most_recent"            = true
   #   "before_compute"         = true
   #   service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
   #    timeouts = {
   #     create = "30m"
   #     delete = "20m"
   #      update = "30m"
   #   }
    #}

    #eks-pod-identity-agent = {
    #  most_recent = true
    #}

  }
}

