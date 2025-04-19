# AWS GitOps Scale Infrastructure with EKS and VPC

A comprehensive Infrastructure as Code (IaC) solution that enables scalable GitOps deployments on AWS using EKS clusters in a hub-spoke architecture with automated infrastructure provisioning and configuration management.

This project provides a complete infrastructure setup using Terragrunt and Terraform to create and manage AWS resources including VPC networking, EKS clusters, and GitOps tooling. It implements a hub-spoke architecture where a central hub cluster manages multiple spoke clusters through GitOps practices, enabling consistent and automated application deployments at scale.

The solution includes automated VPC creation with proper network segmentation, EKS cluster provisioning with secure configurations, and integration with GitOps tools through a bridge component that enables declarative infrastructure and application management.

## Repository Structure
```
.
├── common/                          # Common configuration and variable definitions
│   ├── additional_providers/        # Provider configurations for Kubernetes, Helm, etc.
│   ├── common.hcl                  # Common Terragrunt configuration
│   ├── common.tfvars               # Common Terraform variables
│   └── environment.hcl             # Environment-specific configurations
├── infrastructure/                  # Main infrastructure components
│   ├── containers/                 # Container-related infrastructure
│   │   ├── eks_spoke/             # EKS spoke cluster configuration
│   │   └── gitops_bridge/         # GitOps bridge component setup
│   └── network/                    # Network infrastructure
│       └── vpc/                    # VPC configuration and setup
└── modules/                        # Custom Terraform modules
    └── terraform-aws-gitops-bridge-spoke/  # GitOps bridge implementation
```

## Usage Instructions
### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 0.13
- Terragrunt >= 0.31.0
- kubectl
- helm >= 3.0
- Access to AWS account with necessary permissions

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd gitops-scale-spoke
```

2. Configure AWS credentials:
```bash
aws configure --profile labvel-dev
```

3. Initialize Terragrunt:
```bash
cd infrastructure/network/vpc
terragrunt init
```

### Quick Start

1. Deploy the VPC infrastructure:
```bash
cd infrastructure/network/vpc
terragrunt plan
terragrunt apply
```

2. Deploy the EKS spoke cluster:
```bash
cd infrastructure/containers/eks_spoke
terragrunt plan
terragrunt apply
```

3. Deploy the GitOps bridge:
```bash
cd infrastructure/containers/gitops_bridge
terragrunt plan
terragrunt apply
```

### More Detailed Examples

Creating a VPC with custom CIDR:
```hcl
locals {
  workspace = {
    create = true
    name   = "custom-vpc"
    cidr   = "172.16.0.0/16"
  }
}
```

### Troubleshooting

Common Issues:
1. EKS Cluster Access
```bash
aws eks update-kubeconfig --name <cluster-name> --region us-east-2 --profile labvel-dev
```

2. VPC Subnet Issues
- Check subnet CIDR overlaps
- Verify NAT Gateway configuration
- Ensure proper route table associations

Debug Mode:
```bash
export TF_LOG=DEBUG
terragrunt plan
```

## Data Flow

The infrastructure implements a hub-spoke architecture where the hub cluster manages multiple spoke clusters through GitOps practices.

```ascii
[Hub Cluster] ---> [GitOps Bridge] ---> [Spoke Cluster]
     |                                        |
     |                                        |
     v                                        v
[Git Repos] <------------------------> [AWS Resources]
```

Component Interactions:
1. Hub cluster maintains the source of truth in Git repositories
2. GitOps Bridge synchronizes configurations between hub and spoke clusters
3. Spoke clusters receive configurations and apply them to their resources
4. AWS resources are provisioned and managed through Terraform/Terragrunt
5. VPC provides network isolation and connectivity
6. EKS clusters run workloads in their respective network segments

## Infrastructure

![Infrastructure diagram](./docs/infra.svg)

AWS Resources:

Lambda Functions:
- None defined in current configuration

VPC Resources:
- VPC with CIDR block 10.10.0.0/16
- Public subnets: 10.10.1.0/24, 10.10.2.0/24, 10.10.7.0/24
- Private subnets: 10.10.3.0/24, 10.10.4.0/24, 10.10.8.0/24
- Database subnets: 10.10.5.0/24, 10.10.6.0/24, 10.10.9.0/24
- NAT Gateway
- VPC Flow Logs with CloudWatch integration

EKS Resources:
- EKS Cluster in spoke configuration
- GitOps Bridge deployment
- Kubernetes providers and configurations

## Deployment

Prerequisites:
- AWS credentials with appropriate permissions
- Terraform and Terragrunt installed
- kubectl and helm installed

Deployment Steps:
1. Configure AWS credentials
2. Deploy VPC infrastructure
3. Deploy EKS spoke cluster
4. Deploy GitOps bridge
5. Verify connectivity and configurations

Environment Configurations:
- Development (dev)
- Production (prod)
Each environment has specific variable values defined in common.tfvars