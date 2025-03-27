# AWS Lab: EKS with Fargate, Ingress, Route53, CodePipeline, and IAM Access

This project provisions an end-to-end AWS lab environment using Terraform. It includes:

- EKS Cluster on Fargate
- NGINX Ingress Controller
- AWS ALB + Route53 DNS Record
- `aws-auth` ConfigMap for IAM-based Kubernetes access
- EC2 and CodeBuild integration with Kubernetes using IRSA and IAM roles
- CI/CD with CodePipeline and CodeBuild
- Secure app deployment using Helm

---

## 🔧 Project Setup

### 1. Clone the Repo

```bash
git clone https://github.com/omerrevach/aws-lab.git
cd aws-lab

2. Set Your Variables

Edit terraform.tfvars to include values for:

    VPC config

    Subnets

    Region

    EKS cluster name

    DockerHub credentials

    GitHub token

    Route53 zone IDs

🚀 Deploy with Terraform

terraform init
terraform apply

⚠️ First Apply Error (Expected)

After the first terraform apply, you will see:

Error: configmaps "aws-auth" already exists

This happens because:

    EKS automatically creates the aws-auth ConfigMap

    Terraform is trying to create it again, which causes a conflict

✅ Fix It (One-Time Import)

Run this command to import the existing ConfigMap into Terraform state:

terraform import kubernetes_config_map.aws_auth kube-system/aws-auth

Then apply again:

terraform apply

✅ Now Terraform manages the aws-auth ConfigMap and can update it automatically.