provider "aws" {
  region     = var.region
  access_key = var.access
  secret_key = var.secret
}

resource "aws_instance" "web" {
  ami                    = "ami-03b5297d565ef30a6"
  instance_type          = "t2.micro"
  key_name               = "my_aws"
  vpc_security_group_ids = ["${aws_security_group.terraformsecuritygroup.id}"]
  subnet_id              = aws_subnet.subnet.id
  user_data              = file("httpd.sh")
  tags = {
    Name = "webserver"
  }

}

resource "aws_key_pair" "deployer" {
  key_name   = "my_aws"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCqa7NhG4HhAaLcPzbYd3M0RZfZC8Ih6BmzWBeO2ZRr4yyaFoK+CRlrT82sbt4dH4yUTcfQGS+sOHG+hX+rjB4WBODEIrsq9bDsipVe3ajsqdl30eymnfiL1fY+rfT3VezdAQA845j8fmpNXYuy/LL+1BCF0KPePOZ8zSy28gIF/IV7yEoCKQm0wpHmMBvEvO0wSrQNbREIIfToUTcX/55H2bfaQuc4XBF6fP5CyycjqUJT9Ta5FAGvJV/7FNiHGt6xB53zTB3zJ0MEk0C89/X/jOw9b7g6DxFSBb9WMhlTMDiXezGrCwGDiMGPnu4SXBWPJ7jWQMO4o52bz3QopW0hRhGFQNkPc53HgF4TWqXqqx9VomxyhbjNAhKCkHGxrTqtmJy17pp/rOoZS1fZsJdgtZ0hg3OM9U674YdFB02VElp1tlgFZI0uUaUFfE5YRXk02qY8+H04NUqgpxWy0gGTq3iXv229SHftoIvQniIw+pFdGLAEjjSiJHdZ0WaVT8Kwmo4KV+/4nW1n0SO5kasSKpr5F8dVt/5gDN8pms3plX6da85esU55ZTABbUC1WbzTtou0c+ZNP6MyDBVf+ivtuZMNchu35vZfUUowFZcRoyfpgnR2BN/OtfZSQtE6rwrKsh/5wFBODwHrEgP5pdXKv3veSZzb3q8Ln5DrYKC+tQ== root@jenkins.elk.com"
}

resource "aws_vpc" "myvpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "terraformvpc"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1b"

  tags = {
    Name = "subnet"
  }
}

resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myIGW"
  }
}

resource "aws_route_table" "myrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }
  tags = {
    Name = "myrt"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.myrt.id
}

resource "aws_security_group" "terraformsecuritygroup" {
  vpc_id      = aws_vpc.myvpc.id
  description = "Allow 80 and 22 port traffic"
  ingress {
    description = "allow 80 port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow 22 port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_80 and 22 port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "aws_instance_public_dns" {
  value = aws_instance.web.public_dns
}


output "aws_instance_public_ip" {
  value = aws_instance.web.public_ip
}

