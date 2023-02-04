provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "project_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "Prod_vpc"
  }
}

# Internet gateway
resource "aws_internet_gateway" "project_internet_gateway" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Name = "prod_internet_gateway"
  }
}

# create route table
resource "aws_route_table" "project_route_table" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_internet_gateway.id
  }

  tags = {
    Name = "Prod-route-table-public"
  }
}

# Create Public Subnet-1
resource "aws_subnet" "project-public-subnet1" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "Prod-public-subnet1"
  }
}


# Create Public Subnet-2
resource "aws_subnet" "project-public-subnet2" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "Prod-public-subnet2"
  }
}


# Associate public subnet 1 with public route table
resource "aws_route_table_association" "project-public-subnet1-association" {
  subnet_id      = aws_subnet.project-public-subnet1.id
  route_table_id = aws_route_table.project_route_table.id
}

# Associate public subnet 2 with public route table
resource "aws_route_table_association" "project-public-subnet2-association" {
  subnet_id      = aws_subnet.project-public-subnet2.id
  route_table_id = aws_route_table.project_route_table.id
}

# Create network acl
resource "aws_network_acl" "project-network-acl" {
  vpc_id     = aws_vpc.project_vpc.id
  subnet_ids = [aws_subnet.project-public-subnet1.id, aws_subnet.project-public-subnet2.id]


  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

}

# Create a security group for the load balancer
resource "aws_security_group" "project-load_balancer_sg" {
  name        = "project-load-balancer-sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.project_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# security group 
resource "aws_security_group" "project-security-grp-rule" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.project_vpc.id

  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.project-load_balancer_sg.id]
  }
  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.project-load_balancer_sg.id]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "Prod-security-grp-rule"
  }
}

# Create an Application Load Balancer
resource "aws_lb" "project-load-balancer" {
  name               = "project-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.project-load_balancer_sg.id]
  subnets            = [aws_subnet.project-public-subnet1.id, aws_subnet.project-public-subnet2.id]
  enable_deletion_protection = false
  depends_on                 = [aws_instance.Server1, aws_instance.Server2, aws_instance.Server3]
}


# creating target group
resource "aws_lb_target_group" "project-target-group" {
  name        = "project-target-group"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.project_vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# Create the listener
resource "aws_lb_listener" "project-listener" {
  load_balancer_arn = aws_lb.project-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project-target-group.arn
  }
}
# Create the listener rule
resource "aws_lb_listener_rule" "project-listener-rule" {
  listener_arn = aws_lb_listener.project-listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project-target-group.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# Attach the target group to the load balancer
resource "aws_lb_target_group_attachment" "project-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.project-target-group.arn
  target_id        = aws_instance.Server1.id
  port             = 80
}
 
resource "aws_lb_target_group_attachment" "project-target-group-attachment2" {
  target_group_arn = aws_lb_target_group.project-target-group.arn
  target_id        = aws_instance.Server2.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "project-target-group-attachment3" {
  target_group_arn = aws_lb_target_group.project-target-group.arn
  target_id        = aws_instance.Server3.id
  port             = 80 
}

output "elb_target_group_arn" {
  value = aws_lb_target_group.project-target-group.arn
}

output "elb_load_balancer_dns_name" {
  value = aws_lb.project-load-balancer.dns_name
}

output "elastic_load_balancer_zone_id" {
  value = aws_lb.project-load-balancer.zone_id
}








