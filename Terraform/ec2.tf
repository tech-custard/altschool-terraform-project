# creating instance 1
resource "aws_instance" "Server1" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "project"
  security_groups   = [aws_security_group.project-security-grp-rule.id]
  subnet_id         = aws_subnet.project-public-subnet1.id
  availability_zone = "us-east-1a"
  tags = {
    Name   = "Server1"
    source = "terraform"
  }
}
# creating instance 2
resource "aws_instance" "Server2" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "project"
  security_groups   = [aws_security_group.project-security-grp-rule.id]
  subnet_id         = aws_subnet.project-public-subnet2.id
  availability_zone = "us-east-1b"
  tags = {
    Name   = "Server2"
    source = "terraform"
  }
}
# creating instance 3
resource "aws_instance" "Server3" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "project"
  security_groups   = [aws_security_group.project-security-grp-rule.id]
  subnet_id         = aws_subnet.project-public-subnet1.id
  availability_zone = "us-east-1a"
  tags = {
    Name   = "Server3"
    source = "terraform"
  }
}


resource "local_file" "Ip_address" {
  filename = "host-inventory"
  content  = <<EOT
${aws_instance.Server1.public_ip}
${aws_instance.Server2.public_ip}
${aws_instance.Server3.public_ip}
  EOT
}