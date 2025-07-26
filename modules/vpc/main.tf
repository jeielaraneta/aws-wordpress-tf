resource "aws_vpc" "vpc" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "${var.vpc_prefix}-${var.env_name}-vpc"
    }
}

#internet gateway
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.vpc.id

  tags = {
     Name = "${var.vpc_prefix}-${var.env_name}-igw"
  }
}

#public subnets
resource "aws_subnet" "public_subnets" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = "${length(var.availability_zones)}"
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index * 2)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_prefix}-${var.env_name}-public-subnet-${count.index}"
    LogicalPlacement = "public"
  }
}

#private subnets
resource "aws_subnet" "private_subnets" {
  vpc_id              = aws_vpc.vpc.id
  count               = "${length(var.availability_zones)}"
  cidr_block          = cidrsubnet(aws_vpc.vpc.cidr_block, 8, (count.index+4)*2)
  availability_zone   = var.availability_zones[count.index]
  tags = {
    Name = "${var.vpc_prefix}-${var.env_name}-private-subnet-${count.index}"
    LogicalPlacement = "private"
  }
}

#database subnets
resource "aws_subnet" "database_subnets" {
  vpc_id              = aws_vpc.vpc.id
  count               = "${length(var.availability_zones)}"
  cidr_block          = cidrsubnet(aws_vpc.vpc.cidr_block, 8, (count.index+8)*2)
  availability_zone   = var.availability_zones[count.index]
  tags = {
    Name = "${var.vpc_prefix}-${var.env_name}-database-subnet-${count.index}"
    LogicalPlacement = "database"
  }
}

#Elastic IP
resource "aws_eip" "natg_eip" {
  vpc = true
  #count = length(local.public_subnets)
  tags = {
    Name = "${var.vpc_prefix}-${var.env_name}-public-natg-eip"
    Owner = "CcstMainWebsite"
  }
}

#NAT Gateway
resource "aws_nat_gateway" "public_natg" {
  #count         = length(local.public_subnets)
  allocation_id = aws_eip.natg_eip.id
  subnet_id     = data.aws_subnets.public.ids[0]

  tags = {
    Name = "${var.vpc_prefix}-${var.env_name}-public-natg"
    LogicalPlacement = "public"
    Owner = "CcstMainWebsite"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [
    aws_eip.natg_eip,
    aws_internet_gateway.default, 
    aws_subnet.public_subnets
  ]
}

#public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
  tags = {
    Name = "${var.vpc_prefix}-${var.env_name}-public-rt"
  }
}

#private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
  #count  = length(local.public_subnets)
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_natg.id
  }
  tags = {
    Name = "${var.vpc_prefix}-${var.env_name}-private-rt"
    LogicalPlacement = "private"
  }

  depends_on = [aws_nat_gateway.public_natg]
}

#database route table
# resource "aws_route_table" "database_rt" {
#   vpc_id = aws_vpc.vpc.id
#   tags = {
#     Name = "${var.vpc_prefix}-${var.env_name}-database-rt"
#     LogicalPlacement = "database"
#   }

#   depends_on = [aws_subnet.database_subnets]
# }

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.vpc.id]
  }
  tags = {
    LogicalPlacement = "public"
  }

  depends_on = [aws_subnet.public_subnets]
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.vpc.id]
  }
  tags = {
    LogicalPlacement = "private"
  }

  depends_on = [aws_subnet.private_subnets]
}

# data "aws_subnets" "database" {
#   filter {
#     name   = "vpc-id"
#     values = [aws_vpc.vpc.id]
#   }
#   tags = {
#     LogicalPlacement = "database"
#   }

#   depends_on = [aws_subnet.database_subnets]
# }

locals {
  public_subnets = [for i in range(length(var.availability_zones)): data.aws_subnets.public.ids[i]]
  private_subnets = [for i in range(length(var.availability_zones)): data.aws_subnets.private.ids[i]]
  #database_subnets = [for i in range(length(var.availability_zones)): data.aws_subnets.database.ids[i]]

  depends_on = [
    data.aws_subnets.private,
    data.aws_subnets.public,
    #data.aws_subnets.database
  ]
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(local.public_subnets)
  subnet_id      = data.aws_subnets.public.ids[count.index]
  route_table_id = aws_route_table.public_rt.id

  depends_on = [
    aws_vpc.vpc,
    aws_route_table.public_rt,
    aws_subnet.public_subnets
  ]
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(local.private_subnets)
  subnet_id      = data.aws_subnets.private.ids[count.index]
  route_table_id = aws_route_table.private_rt.id

  depends_on = [
    aws_route_table.private_rt,
    aws_subnet.private_subnets
  ]
}

# resource "aws_route_table_association" "database_assoc" {
#   count          = length(local.dabase_subnets)
#   subnet_id      = data.aws_subnets.database.ids[count.index]
#   route_table_id = aws_route_table.database_rt.id

#   depends_on = [
#     aws_vpc.vpc,
#     aws_route_table.database_rt,
#     aws_subnet.database_subnets
#   ]
# }

# resource "aws_security_group" "rds_secgroup" {
#   name        = "${var.vpc_prefix}-${var.env_name}-rds-sg"
#   description = "RDS Security Group"
#   vpc_id      = aws_vpc.vpc.id

#   ingress {
#     from_port        = 3306
#     to_port          = 3306
#     protocol         = "tcp"
#     cidr_blocks      = [aws_vpc.vpc.cidr_block]
#   }

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${var.vpc_prefix}-${var.env_name}-rds-sg"
#   }

#   lifecycle {
#     # Necessary if changing 'name' or 'name_prefix' properties.
#     create_before_destroy = true
#   }
# }

#Load Balancer Security Group
resource "aws_security_group" "loadbalancer_secgroup" {
  name        = "${var.vpc_prefix}-${var.env_name}-lb-sg"
  description = "Load Balancer Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # ingress {
  #   from_port        = 80
  #   to_port          = 80
  #   protocol         = "tcp"
  #   cidr_blocks      = ["0.0.0.0/0"]
  # }

  # egress {
  #   from_port   = 0
  #   to_port     = 65535
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_prefix}-${var.env_name}-lb-sg"
  }

  lifecycle {
    # Necessary if changing 'name' or 'name_prefix' properties.
    create_before_destroy = true
  }
}

#EC2 Security Group
resource "aws_security_group" "ec2_secgroup" {
  name        = "${var.vpc_prefix}-${var.env_name}-ec2-sg"
  description = "EC2 Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    security_groups   = [aws_security_group.loadbalancer_secgroup.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # egress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   security_groups   = [aws_security_group.loadbalancer_secgroup.id]
  # }

  tags = {
    Name = "${var.vpc_prefix}-${var.env_name}-ec2-sg"
  }

  lifecycle {
    # Necessary if changing 'name' or 'name_prefix' properties.
    create_before_destroy = true
  }
}

# resource "aws_db_subnet_group" "rds_subnet_group" {
#   name       = "${var.vpc_prefix}-${var.env_name}-db-subnet-group"
#   subnet_ids = data.aws_subnets.database.ids

#   tags = {
#     Name = "${var.vpc_prefix}-${var.env_name}-db-subnet-group"
#   }
# }