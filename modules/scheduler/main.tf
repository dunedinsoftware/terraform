
locals {
  component = "${var.environment}-scheduler"
}

# create ec2 iam role for the scheduler
resource "aws_iam_role" "scheduler" {
  name = local.component
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
EOF
}

# create iam instance profile for ec2 instance
resource "aws_iam_policy" "scheduler" {
  name = local.component

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ],
        "Resource": "*"
      }
    ]
  }
EOF
}

# associate policy with iam role
resource "aws_iam_role_policy_attachment" "scheduler" {
  role       = aws_iam_role.scheduler.name
  policy_arn = aws_iam_policy.scheduler.arn
}

# create iam instance policy
resource "aws_iam_instance_profile" "scheduler" {
  name = local.component
  role = aws_iam_role.scheduler.name
}

# create security group for the instance
resource "aws_security_group" "scheduler" {
  name = local.component
  description = "Allow traffic to the Scheduler EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
 }
}

# generate SSH key pair for the scheduler
resource "tls_private_key" "scheduler" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# key pairs are region-specific
resource "aws_key_pair" "scheduler" {
  key_name   = local.component
  public_key = tls_private_key.scheduler.public_key_openssh
}

resource "aws_secretsmanager_secret" "scheduler" {
  name     = "${local.component}-ssh-key"
  description = "Contains the PEM SSH key for the specified environment"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "scheduler" {
  secret_id     = aws_secretsmanager_secret.scheduler.id
  secret_string = tls_private_key.scheduler.private_key_pem
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

# create ec2 instance
resource "aws_instance" "scheduler" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.scheduler.id]
  subnet_id = var.subnet_id
  iam_instance_profile = aws_iam_instance_profile.scheduler.name
  key_name = aws_key_pair.scheduler.key_name
  hibernation = false

  provisioner "file" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = tls_private_key.scheduler.private_key_openssh
      host     = "${self.private_ip}"
    }
    source = "${path.module}/files/monitoring/scheduler.sh"
    destination = "/home/ubuntu/scheduler.sh"
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = tls_private_key.scheduler.private_key_openssh
      host     = "${self.private_ip}"
    }

    inline = [
      "sudo apt install jq -y",
      "chmod +x /home/ubuntu/scheduler.sh && /home/ubuntu/scheduler.sh",
    ]
  }

  tags = {
    Name = local.component
  }
}
