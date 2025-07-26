terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

data "aws_availability_zones" "available" {
  all_availability_zones = true
  
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

provider "aws" {
  region  = var.region

  default_tags {
    tags = {
      Environment = var.environment
      Owner       = var.owner
      Application = var.application_name
      CostAllocation = var.owner
    }
  }
}

locals {
  selected_azs = {
    "dev"   = [for i in range(var.number_of_selected_az): data.aws_availability_zones.available.names[i]]
    "staging" = [for i in range(var.number_of_selected_az): data.aws_availability_zones.available.names[i]]
    "prod"  = [for i in range(var.number_of_selected_az): data.aws_availability_zones.available.names[i]] #data.aws_availability_zones.available.names
  }
}

data "aws_caller_identity" "current" {}

module "iam" {
  source = "../modules/iam"

  iam_prefix          = var.application_name
  env_name            = var.environment
  account_id          = data.aws_caller_identity.current.account_id
}

module "vpc" {
  source = "../modules/vpc"

  vpc_prefix          = var.application_name
  env_name            = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = local.selected_azs[var.environment]
}

module "ec2" {
  source = "../modules/ec2"

  ec2_prefix          = var.application_name
  env_name            = var.environment
  ec2_type            = var.ec2_type
  ec2_ami_id          = var.ec2_ami_id
  certificate_domain  = var.certificate_domain
  url                 = var.url
  private_subnets     = module.vpc.private_subnets
  public_subnets      = module.vpc.public_subnets
  ec2_security_group_id   = module.vpc.ec2_secgroup_id
  lb_security_group_id    = module.vpc.loadbalancer_secgroup_id
  key_name                = var.key_name
  availability_zone       = local.selected_azs[var.environment][0]
  instance_profile        = module.iam.ec2_profile
  vpc_id = module.vpc.vpc_id
  route53 = module.route_53
  ebs_size                = var.ebs_size

  depends_on = [ module.vpc, module.iam ]
}

module "route_53" {
  source              = "../modules/route_53"
  route53_hosted_zone = var.route53_hosted_zone
  alb_dns             = module.ec2.alb.dns_name
  alb_zone_id         = module.ec2.alb.zone_id
  record_name         = var.record_name
  depends_on          = [module.ec2.alb]
}

# module "secrets_manager" {
#   source      = "../modules/secrets_manager"
#   prefix      = var.application_name
#   env_name    = var.environment
#   db_username = var.db_username
# }

# module "rds" {
#   source                  = "../modules/rds"
#   db_prefix               = var.application_name
#   env_name                = var.environment
#   subnet_group_name       = module.vpc.rds_subnet_group
#   security_group_id       = module.vpc.rds_security_group_id
#   rds_secrets             = module.secrets_manager.rds_secrets
#   skip_rds_final_snapshot = var.skip_rds_final_snapshot
#   depends_on              = [module.vpc]
#   availability_zones      = local.selected_azs[var.environment]
# }

# module "beanstalk" {
#   source              = "../modules/beanstalk"
#   beanstalk_prefix    = var.application_name
#   env_name            = var.environment
#   vpc_id              = module.vpc.vpc_id
#   ec2_subnets         = module.vpc.private_subnets
#   alb_subnets         = module.vpc.public_subnets
#   keypair             = var.keypair
#   beanstalk_ec2_type  = var.beanstalk_ec2_type
#   beanstalk_ec2_role  = module.iam.elasticbeanstalk_ec2_profile.arn
#   beanstalk_service_role  = module.iam.elasticbeanstalk_service_linked_role.arn
#   depends_on          = [module.vpc]
# }

