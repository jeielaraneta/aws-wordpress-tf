data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Get .sh file to start wordpress service
data "template_file" "user_data_start" {
  template = file("${path.module}/start_wordpress.sh",)

  vars = {
    URL = var.url
    WP_CONFIG = "wordpress/wp-config.php"
  }
}

#EC2
resource "aws_instance" "webserver" {
  ami                    = var.ec2_ami_id != "none" ? var.ec2_ami_id : data.aws_ami.amzn-linux-2023-ami.id
  instance_type          = var.ec2_type
  key_name               = var.key_name
  security_groups        = [var.ec2_security_group_id]
  subnet_id              = var.private_subnets[0]
  iam_instance_profile   = var.instance_profile.name

  user_data = data.template_file.user_data_start.rendered

  root_block_device {
    volume_type           = "gp3" # Specify the desired EBS volume type
    volume_size           = var.ebs_size   # Specify the size of the EBS volume in GiB
    delete_on_termination = true # The root volume is typically deleted on instance termination
  }
  tags = {
    Name = "${var.ec2_prefix}-${var.env_name}-ec2"
  }

  depends_on = [ 
    var.route53
  ]
}

# ALB
resource "aws_lb" "alb" {
  name               = "${var.ec2_prefix}-${var.env_name}-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [var.lb_security_group_id]
}

# HTTP Target Group
resource "aws_lb_target_group" "http_target_group" {
  name     = "${var.ec2_prefix}-${var.env_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-302"
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "attachment" {
  target_group_arn = aws_lb_target_group.http_target_group.arn
  target_id        = aws_instance.webserver.id
  port             = 80
}
# Get ACM Certificate ARN
data "aws_acm_certificate" "cert_domain" {
  domain   = var.certificate_domain
  statuses = ["ISSUED"]
}

# HTTPS Listener
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  
  certificate_arn = data.aws_acm_certificate.cert_domain.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_target_group.arn
  }
}

#HTTP Listener
# resource "aws_lb_listener" "http_redirect" {
#   load_balancer_arn = aws_lb.alb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "redirect"
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_302"
#     }
#   }
# }

