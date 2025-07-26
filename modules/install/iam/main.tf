data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ssm_core_policy" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ec2_assume_role" {
  name                = "${var.iam_prefix}-${var.env_name}-ec2-assume-role"
  assume_role_policy  = data.aws_iam_policy_document.ec2_assume_role_policy.json
  managed_policy_arns = [
    data.aws_iam_policy.ssm_core_policy.arn
  ]
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.iam_prefix}-${var.env_name}-ec2-role"
  role = aws_iam_role.ec2_assume_role.name
}