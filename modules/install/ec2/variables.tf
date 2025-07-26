variable "ec2_prefix" {
    description = "Abbreviation of the client company's name. Example: ccst"
    type = string
}

variable "env_name" {
    description = "Name of the environment"
    type = string
}

variable "ec2_type" {
  
}

variable "ec2_ami_id" {
  default = "none"
}

variable "certificate_domain" {

}

variable "private_subnets" {

}

variable "public_subnets" {

}

variable "ec2_security_group_id" {
  
}

variable "lb_security_group_id" {
  
}

variable "key_name" {
  
}

variable "availability_zone" {

}

variable "instance_profile" {
  
}

variable "vpc_id" {
  
}

variable "route53" {
  
}