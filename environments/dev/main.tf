terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket = "utc-app-tfstate"
  #   key    = "dev/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

module "network" {
  source = "../../modules/network"

  app_name    = var.app_name
  environment = "dev"

  vpc_cidr             = var.vpc_cidr
  az_count             = var.az_count
  public_subnet_cidrs  = var.public_subnet_cidrs
  app_subnet_cidrs     = var.app_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  nat_gateway_count    = var.nat_gateway_count

  tags = var.tags
}

module "security" {
  source = "../../modules/security"

  app_name    = var.app_name
  environment = "dev"
  vpc_id      = module.network.vpc_id

  alb_ingress_cidrs = var.alb_ingress_cidrs
  alb_ports         = var.alb_ports
  app_port          = var.app_port
  db_port           = var.db_port

  tags = var.tags
}


module "loadbalancer" {
  source = "../../modules/loadbalancer"

  app_name    = var.app_name
  environment = "dev"

  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids_list
  alb_security_group_id  = module.security.alb_security_group_id

  certificate_domain  = var.certificate_domain
  app_port            = var.app_port

  tags = var.tags
}


module "cdn" {
  source = "../../modules/cdn"

  app_name    = var.app_name
  environment = "dev"

  alb_dns_name    = module.loadbalancer.alb_dns_name
  certificate_arn = module.loadbalancer.certificate_arn

  zone_name   = var.zone_name
  record_name = var.record_name
  logging_bucket = var.logging_bucket

  tags = var.tags
}




module "compute" {
  source = "../../modules/compute"

  app_name    = var.app_name
  environment = "dev"

  app_subnet_ids         = module.network.app_subnet_ids_list
  app_security_group_id  = module.security.app_security_group_id

  target_group_arn          = module.loadbalancer.target_group_arn
  alb_arn_suffix             = module.loadbalancer.alb_arn_suffix
  target_group_arn_suffix    = module.loadbalancer.target_group_arn_suffix

  iam_instance_profile_name = module.iam.instance_profile_name

  efs_file_system_id    = module.storage.efs_file_system_id
  efs_access_point_id   = module.storage.efs_access_point_id

  app_secret_arn = module.secrets.secret_arn
  db_secret_arn  = module.database.master_user_secret_arn

  instance_type    = var.instance_type
  aws_region       = var.aws_region
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  app_port         = var.app_port



# Additional variables for the compute module
# This block is added to provide the necessary variables for the compute module, including EFS and secret ARNs, as well as instance configuration parameters.
  deploy_bucket = module.storage.s3_bucket_name
  deploy_prefix = "deploy/"
  db_host       = module.database.db_address
  db_port       = module.database.db_port
  db_name       = module.database.db_name

  tags = var.tags
}





module "database" {
  source = "../../modules/database"

  app_name    = var.app_name
  environment = "dev"

  db_subnet_ids         = module.network.db_subnet_ids_list
  db_security_group_id  = module.security.db_security_group_id

    engine_major_version = var.db_engine_major_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  db_name           = var.db_name
  username          = var.db_username
  port              = var.db_port

  multi_az                 = var.db_multi_az
  backup_retention_period  = var.db_backup_retention_period
  deletion_protection      = var.db_deletion_protection
  skip_final_snapshot      = var.db_skip_final_snapshot

  tags = var.tags
}


module "storage" {
  source = "../../modules/storage"

  app_name    = var.app_name
  environment = "dev"

  vpc_id                 = module.network.vpc_id
  app_subnet_ids         = module.network.app_subnet_ids_list
  app_security_group_id  = module.security.app_security_group_id

  s3_force_destroy = var.s3_force_destroy

  tags = var.tags
}



module "iam" {
  source = "../../modules/iam"

  app_name    = var.app_name
  environment = "dev"

  s3_bucket_arn         = module.storage.s3_bucket_arn
    efs_file_system_arn   = module.storage.efs_file_system_arn
  efs_access_point_arn  = module.storage.efs_access_point_arn
  db_secret_arn         = module.database.master_user_secret_arn

  tags = var.tags
}



module "secrets" {
  source = "../../modules/secrets"

  app_name    = var.app_name
  environment = "dev"

  app_role_name = module.iam.role_name
  secret_keys   = var.app_secret_keys

  recovery_window_in_days = var.secret_recovery_window_days

  tags = var.tags
}




module "observability" {
  source = "../../modules/observability"

  app_name    = var.app_name
  environment = "dev"

  alert_email_addresses = var.alert_email_addresses

  autoscaling_group_name  = module.compute.autoscaling_group_name
  alb_arn_suffix           = module.loadbalancer.alb_arn_suffix
  target_group_arn_suffix  = module.loadbalancer.target_group_arn_suffix
  db_instance_id           = module.database.db_instance_id

  tags = var.tags
}



module "cicd" {
  source = "../../modules/cicd"

  app_name    = var.app_name
  environment = "dev"

  github_org  = var.github_org
  github_repo = var.github_repo
  github_org_id = var.github_org_id
  github_repo_id = var.github_repo_id
  create_oidc_provider = var.create_oidc_provider

  deploy_bucket_arn = module.storage.s3_bucket_arn

  tags = var.tags
}