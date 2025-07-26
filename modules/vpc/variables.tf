variable "vpc_prefix" {
    description = "Abbreviation of the client company's name. Example: ccst"
    type = string
}

variable "env_name" {
    description = "Name of the environment"
    type = string
}

variable "vpc_cidr" {
    description = "CIDR of the VPC"
    default = "10.192.0.0/16"
}

variable "availability_zones" {}