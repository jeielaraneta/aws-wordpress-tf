# output "elasticbeanstalk_ec2_profile" {
#   value = aws_iam_instance_profile.elasticbeanstalk_ec2_profile
# }

# output "elasticbeanstalk_service_linked_role" {
#   value = aws_iam_service_linked_role.elasticbeanstalk_service_linked_role
# }

output "alb" {
  value = aws_lb.alb
}