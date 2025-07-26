output "vpc_id" {
    value = aws_vpc.vpc.id
}

output "loadbalancer_secgroup_id" {
    value = aws_security_group.loadbalancer_secgroup.id
}

output "ec2_secgroup_id" {
    value = aws_security_group.ec2_secgroup.id
}

output "public_subnets" {
    value = local.public_subnets
}

output "private_subnets" {
    value = local.private_subnets
}