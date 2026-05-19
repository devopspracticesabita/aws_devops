# 1. Fetch the latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS Owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 2. Create a Security Group for Public Access
resource "aws_security_group" "public_sg" {
  name        = "${var.environment_name}-public-sg"
  description = "Allow SSH, HTTP, and HTTPS from anywhere"
  vpc_id      = var.vpc_id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS Access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules (Allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.environment_name}-public-sg" })
}

# 3. Create the EC2 Instance
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu_24_04.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
  }

  tags = merge(var.tags, { Name = "${var.environment_name}-baston-host" })
}