module "vpc" {
  source           = "./module/vpc"
  environment_name = var.environment_name
  vpc_cidr         = var.vpc_cidr
  subnet_newbits   = var.subnet_newbits
  tags             = var.tags
}

# module "eks" {
#   source = "./module/eks" # This points to the folder containing your locals.tf

#   # Pass any required variables here
#   private_subnet_ids  = module.vpc.private_subnet_ids
#   public_subnets_map  = module.vpc.public_subnets_map
#   private_subnets_map = module.vpc.private_subnets_map
#   cluster_name = var.cluster_name
#   aws_region = var.aws_region
#   environment_name = var.environment_name
#   business_division = var.business_division
#   cluster_version = var.cluster_version
#   dynamodb_table_arn = module.app_db.table_arn
#   redis_user_arn      = module.redis.redis_user_arn
#   depends_on = [ module.vpc ]
#   vpc_id = module.vpc.vpc_id # Pass VPC ID for Karpenter resources NEW FOR KARPENTER
# }

module "eks" {
  source = "./module/eks_fargate" # This points to the folder containing your locals.tf

  # Pass any required variables here
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnets_map  = module.vpc.public_subnets_map
  private_subnets_map = module.vpc.private_subnets_map
  cluster_name        = var.cluster_name
  aws_region          = var.aws_region
  environment_name    = var.environment_name
  business_division   = var.business_division
  cluster_version     = var.cluster_version
  dynamodb_table_arn  = module.app_db.table_arn
  redis_user_arn      = module.redis.redis_user_arn
  depends_on          = [module.vpc]
  vpc_id              = module.vpc.vpc_id # Pass VPC ID for Karpenter resources NEW FOR KARPENTER
  providers = {
    aws     = aws
    kubectl = kubectl # Forces the module to use alekc/kubectl instead of looking for hashicorp/kubectl
  }
}

module "pod_identity_secret_manager_ebs_csi_driver" {
  source             = "./module/pod_identity_secret_manager_ebs_csi_driver"
  role_name          = "eks-pod-s3-read-role-csi-secret-manager-ebs_csi_driver"
  clusters           = [module.eks.eks_cluster_name]
  namespace          = var.namespace
  service_account    = var.service_account
  kubernetes_version = module.eks.eks_cluster_version
  csi_driver_status  = helm_release.csi_secrets_store.status
  #dynamodb_table_arn = module.app_db.table_arn
  depends_on = [
    module.eks,
    helm_release.csi_secrets_store,
    helm_release.secrets_provider_aws
  ]
  providers = {
    aws     = aws
    kubectl = kubectl # Forces the module to use alekc/kubectl instead of looking for hashicorp/kubectl
  }
}

module "rds" {
  source                = "./module/rds"
  environment_name      = var.environment_name
  tags                  = var.tags
  eks_sg_id             = module.eks.eks_cluster_security_group_id
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  multi_az              = var.multi_az            # Set to true for production HA
  create_read_replica   = var.create_read_replica # Set to true if you need a read-only node
  instance_class        = var.instance_class
  max_allocated_storage = var.max_allocated_storage
}

module "route_53_external_dns" {
  source           = "./module/route_53_external_dns"
  vpc_id           = module.vpc.vpc_id
  rds_address      = module.rds.rds_endpoint_address
  environment_name = var.environment_name
  clusters         = [module.eks.eks_cluster_name]

  depends_on = [module.eks]
}

data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

module "alb_ingress_load_balancer_controller" {
  source          = "./module/alb_ingress_load_balancer_controller"
  role_name       = "eks-alb-ingress-controller-role-${var.aws_region}"
  clusters        = [module.eks.eks_cluster_name]
  lbc_policy_json = data.http.lbc_iam_policy.response_body

  depends_on = [
    module.pod_identity_secret_manager_ebs_csi_driver
  ]
  providers = {
    aws     = aws
    kubectl = kubectl # Forces the module to use alekc/kubectl instead of looking for hashicorp/kubectl
  }
}

module "app_db" {
  source              = "./module/dynamodb"
  environment_name    = var.environment_name
  table_name          = var.table_name
  hash_key            = var.hash_key
  hash_key_type       = var.hash_key_type
  deletion_protection = var.deletion_protection
  tags                = var.tags
}

module "postgres_db" {
  source                  = "./module/postgres"
  environment_name        = var.environment_name
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  eks_sg_id               = module.eks.eks_cluster_security_group_id
  db_secret_name          = var.db_secret_name
  max_allocated_storage   = var.max_allocated_storage
  multi_az                = var.multi_az # Set to true for production HA
  create_read_replica     = var.create_read_replica
  postgres_instance_class = var.postgres_instance_class
  tags                    = var.tags
}

module "redis" {
  source = "./module/redis"

  environment_name     = var.environment_name
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  eks_sg_id            = module.eks.eks_cluster_security_group_id
  redis_version        = var.redis_version
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_clusters
  multi_az             = var.multi_az
  parameter_group_name = var.parameter_group_name # Match the engine version

  tags = var.tags
}

# module "ec2_instance" {
#   source           = "./module/ec2"
#   vpc_id           = module.vpc.vpc_id
#   public_subnet_id = values(module.vpc.public_subnet_ids)[0]   
#   instance_type    = var.instance_type
#   environment_name = var.environment_name
#   key_name         = var.key_name

#   tags = var.tags
# }

# module "vpc_mumbai" {
#   source               = "./module/vpc"
#   environment_name     = "${var.environment_name}-mumbai"
#   vpc_cidr             = var.sagemaker_vpc_cidr
#   aws_region           = var.sagemaker_region
#   enable_vpc_endpoints = false
#   subnet_newbits       = var.subnet_newbits
#   tags                 = var.tags

#   providers = {
#     aws = aws.mumbai
#   }
# }

# module "vpc_peering" {
#   source = "./module/vpc-peering"

#   pair_name                = "hyd-to-mum"
#   requestor_vpc_id         = module.vpc.vpc_id
#   accepter_vpc_id          = module.vpc_mumbai.vpc_id
#   accepter_region          = var.sagemaker_region
#   requestor_cidr           = var.vpc_cidr
#   accepter_cidr            = var.sagemaker_vpc_cidr
#   requestor_route_table_id = module.vpc.private_route_table_id
#   accepter_route_table_id  = module.vpc_mumbai.private_route_table_id
#   tags                     = var.tags

#   providers = {
#     aws.requester = aws        # Default (ap-south-2)
#     aws.accepter  = aws.mumbai # Alias (ap-south-1)
#   }
# }

# module "sagemaker_studio" {
#   source = "./module/sagemaker"
#   environment_name   = var.environment_name
#   aws_region         = var.sagemaker_region
#   vpc_id             = module.vpc_mumbai.vpc_id
#   private_subnet_ids = module.vpc_mumbai.private_subnet_ids

#   providers = {
#     aws = aws.mumbai
#   }

#   tags = var.tags
# }

# module "my_ecr_repo" {
#   source               = "./module/ecr"
#   repository_name      = var.repository_name
#   image_tag_mutability = var.image_tag_mutability
#   scan_on_push         = var.scan_on_push

#   tags = var.tags
# }

module "efs" {
  source = "./module/efs"

  business_division   = var.business_division
  environment_name    = var.environment_name
  private_subnets_map = module.vpc.private_subnets_map
  tags                = var.tags

  vpc_id               = module.vpc.vpc_id
  karpenter_node_sg_id = module.eks.karpenter_node_sg_id

  depends_on = [
    module.eks,                                         # Cluster API must be reachable
    module.pod_identity_secret_manager_ebs_csi_driver,  # EFS CSI Add-on driver must be fully registered
    helm_release.csi_secrets_store                      # Core CSI Custom Resource Definitions must exist
  ]
}
