resource "aws_vpc" "production-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "production-subnet-1" {
  vpc_id     = aws_vpc.production-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1"
}

resource "aws_internet_gateway" "production-ig" {
  vpc_id = aws_vpc.production-vpc.id
}

resource "aws_route_table" "production-subnet-1-route-table" {
  vpc_id = aws_vpc.production-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.production-ig.id
  }
  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.production-ig.id
  }
}

resource "aws_route_table_association" "production-subnet-1-association-1" {
  subnet_id      = aws_subnet.production-subnet-1.id
  route_table_id = aws_route_table.production-subnet-1-route-table.id
}

resource "aws_security_group" "production-security-group" {
  name        = "allow_all"
  description = "Allow All Traffic"
  vpc_id      = aws_vpc.production-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    # ALLOW ALL
  }
}

resource "aws_network_interface" "production-ec2-1-NI" {
  subnet_id       = aws_subnet.production-subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.production-security-group.id]
}

resource "aws_eip" "production-eip" {
  vpc                       = true
  network_interface         =  aws_network_interface.production-ec2-1-NI.id
  associate_with_private_ip = "10.0.1.50"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  availability_zone = "us-east-1"
  network_interface {
    network_interface_id = aws_network_interface.production-ec2-1-NI.id
    device_index = 0
  }
  user_data = <<-EOF
              #!bin/bash
              sudo apt update -y
              sudo apt install nginx -y
              sudo systemctl start nginx
              EOF
}



