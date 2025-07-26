variable "region" {}

variable "application_name" {}

variable "environment" {}

variable "owner" {}

variable "key_name" {}

variable "ec2_type" {}

variable "url" {
  
}

variable "ec2_ami_id" {
  default = "none"
}
variable "certificate_domain" {
  
}
variable "vpc_cidr" {
  
}

variable "db_username" {}

variable "record_name" {
    description = "The sub-domain of the website in Route 53"
    type = string
}

variable "skip_rds_final_snapshot" {}

variable "number_of_selected_az" {}

variable "route53_hosted_zone" {
  
}

variable "ebs_size" {
  
}