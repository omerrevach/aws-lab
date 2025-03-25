module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1.0"

  name                = var.vpc_name
  cidr                = var.vpc_cidr
  azs                 = var.azs
  public_subnets      = var.public_subnets
  private_subnets     = var.private_subnets

  enable_nat_gateway  = true
  single_nat_gateway  = true
  one_nat_gateway_per_az = false  # still uses one unless you want per-AZ

    public_subnet_tags = {
    "kubernetes.io/role/elb"                         = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}"  = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}"  = "shared"
  }

  tags = {
    Name        = var.vpc_name
    Environment = var.environment
    Terraform   = "true"
  }
}


module "s3_bucket" {
  source      = "./modules/s3"
  bucket_name = var.bucket_name
}

module "iam" {
  source                    = "./modules/iam"
  iam_role_name             = var.iam_role_name
  iam_instance_profile_name = var.iam_instance_profile_name
  s3_bucket_arn             = module.s3_bucket.bucket_arn
  vpc_id                    = module.vpc.vpc_id
}

module "eks" {
  source                            = "./modules/eks"
  cluster_name                      = var.eks_cluster_name
  vpc_id                            = module.vpc.vpc_id
  private_subnets                   = module.vpc.private_subnets
  eks_fargate_pod_execution_role_arn = module.iam.eks_fargate_pod_execution_role_arn
  ec2_ssm_role_arn                    = module.iam.ec2_ssm_role_arn
}

module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = "1.31"
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_ingress_nginx                = false
  enable_argocd                       = true

  enable_aws_load_balancer_controller    = true
  aws_load_balancer_controller = {
    set = [
      {
        name  = "vpcId"
        value = module.vpc.vpc_id
      },
      {
        name  = "region"
        value = var.aws_region
      },
    ]
  }

  tags = { Environment = "prod" }

  depends_on = [module.eks]
}

# Helm for Nginx Ingress
resource "helm_release" "ingress_nginx" {
  depends_on = [module.eks_blueprints_addons]
  name       = "ingress-nginx"
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  namespace  = "ingress"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "ClusterIP"  # Keep as ClusterIP as per requirement
  }

  # Add proper tolerations for Fargate
  set {
    name  = "controller.tolerations[0].key"
    value = "eks.amazonaws.com/compute-type"
  }

  set {
    name  = "controller.tolerations[0].value"
    value = "fargate"
  }

  set {
    name  = "controller.tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "controller.tolerations[0].effect"
    value = "NoSchedule"
  }

  # Add nodeSelector for Fargate
  set {
    name  = "controller.nodeSelector.eks\\.amazonaws\\.com/compute-type"
    value = "fargate"
  }

  # Configure admission webhook to work with Fargate
  set {
    name  = "controller.admissionWebhooks.patch.tolerations[0].key"
    value = "eks.amazonaws.com/compute-type"
  }

  set {
    name  = "controller.admissionWebhooks.patch.tolerations[0].value"
    value = "fargate"
  }

  set {
    name  = "controller.admissionWebhooks.patch.tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "controller.admissionWebhooks.patch.tolerations[0].effect"
    value = "NoSchedule"
  }

  # Configure admission webhook with nodeSelector
  set {
    name  = "controller.admissionWebhooks.patch.nodeSelector.eks\\.amazonaws\\.com/compute-type"
    value = "fargate"
  }
  
  # Add resources limits for Fargate
  set {
    name  = "controller.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "128Mi"
  }

  # Critical setting: make it work properly with admission jobs
  set {
    name  = "controller.admissionWebhooks.patch.image.registry"
    value = "registry.k8s.io"
  }

  set {
    name  = "controller.admissionWebhooks.patch.image.image"
    value = "ingress-nginx/kube-webhook-certgen"
  }

  set {
    name  = "controller.admissionWebhooks.patch.image.tag"
    value = "v1.4.0"
  }

  set {
    name  = "controller.admissionWebhooks.patch.image.digest"
    value = "sha256:44d1d0e9f19c63f58b380c5fddaca7cf22c7cee564adeff365225a5df5ef3334"
  }
  
  # Job specific tolerations and nodeSelectors
  set {
    name  = "controller.admissionWebhooks.patch.tolerations[0].key"
    value = "eks.amazonaws.com/compute-type"
  }

  set {
    name  = "controller.admissionWebhooks.patch.tolerations[0].value"
    value = "fargate"
  }

  set {
    name  = "controller.admissionWebhooks.patch.tolerations[0].operator"
    value = "Equal"
  }

  set {
    name  = "controller.admissionWebhooks.patch.tolerations[0].effect"
    value = "NoSchedule"
  }

  # Make sure the jobs get scheduled on Fargate nodes
  set {
    name  = "controller.admissionWebhooks.patch.nodeSelector.eks\\.amazonaws\\.com/compute-type"
    value = "fargate"
  }

  # Ensure the admission jobs can complete
  set {
    name  = "controller.admissionWebhooks.patch.priorityClassName"
    value = ""
  }

  set {
    name  = "controller.admissionWebhooks.patch.podAnnotations.eks\\.amazonaws\\.com/fargate-profile"
    value = "default"
  }
}

resource "time_sleep" "wait_for_nginx" {
  depends_on = [helm_release.ingress_nginx]
  create_duration = "45s"  # Increased to give more time for pods to start
}

data "aws_caller_identity" "current" {}

resource "kubernetes_ingress_v1" "nginx_alb" {
  metadata {
    name      = "nginx-ingress"
    namespace = "ingress"
    annotations = {
      "kubernetes.io/ingress.class"                      = "alb"
      "alb.ingress.kubernetes.io/scheme"                 = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"            = "ip"
      "alb.ingress.kubernetes.io/listen-ports"           = "[{\"HTTP\":80}, {\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/backend-protocol"       = "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-path"       = "/healthz"
      "alb.ingress.kubernetes.io/certificate-arn"        = "arn:aws:acm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:certificate/3f05f383-36e1-4b11-8520-c51a378d9631"
      "alb.ingress.kubernetes.io/ssl-redirect"           = "443"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = "stockpnl.com"
      http {
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "ingress-nginx-controller"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

data "kubernetes_ingress_v1" "alb_ingress" {
  metadata {
    name      = kubernetes_ingress_v1.nginx_alb.metadata[0].name
    namespace = kubernetes_ingress_v1.nginx_alb.metadata[0].namespace
  }

  depends_on = [kubernetes_ingress_v1.nginx_alb]
}

resource "aws_route53_record" "stockpnl_com" {
  zone_id = "Z022564630P941WV72XMM"
  name    = "stockpnl.com"
  type    = "A"

  alias {
    name                   = data.kubernetes_ingress_v1.alb_ingress.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = "Z23TAZ6LKFMNIO" # Always the hosted zone ID for ALB in eu-north-1
    evaluate_target_health = false
  }
}



module "ec2" {
  source               = "./modules/ec2"
  linux_ami            = var.linux_ami
  windows_ami          = var.windows_ami
  instance_type        = var.instance_type
  private_subnets      = module.vpc.private_subnets
  iam_instance_profile = module.iam.ec2_instance_profile
  linux_name           = var.linux_name
  windows_name         = var.windows_name
  k8s_version          = "1.31.0"
  k8s_build            = "2024-03-15"
  vpc_id               = module.vpc.vpc_id
  
  eks_cluster_name     = var.eks_cluster_name
  eks_cluster_endpoint = module.eks.cluster_endpoint
  eks_cluster_ca_data  = module.eks.cluster_certificate_authority_data
  aws_region           = var.aws_region
}


#  IAM role for app
resource "aws_iam_role" "flask_app_role" {
  name = "flask-app-s3-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = module.eks.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(module.eks.oidc_provider_arn, "/^(.*provider\\/)/", "")}:sub": "system:serviceaccount:default:flask-app-sa",
            "${replace(module.eks.oidc_provider_arn, "/^(.*provider\\/)/", "")}:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# IAM policy for S3 access
resource "aws_iam_policy" "flask_app_s3_policy" {
  name        = "flask-app-s3-policy"
  description = "Allow Flask app to access stockpnl-data S3 bucket"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::stockpnl-data",
          "arn:aws:s3:::stockpnl-data/*"
        ]
      }
    ]
  })
}

# Attach policy to the role
resource "aws_iam_role_policy_attachment" "flask_app_s3_attachment" {
  role       = aws_iam_role.flask_app_role.name
  policy_arn = aws_iam_policy.flask_app_s3_policy.arn
}

# Create the Kubernetes service account
resource "kubernetes_service_account" "flask_app_sa" {
  depends_on = [module.eks, aws_iam_role.flask_app_role]
  
  metadata {
    name      = "flask-app-sa"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.flask_app_role.arn
    }
  }
}

