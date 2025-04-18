resource "tls_private_key" "ec2-key" {
    algorithm = "RSA"
}


resource "aws_key_pair" "ec2-key" {
    key_name = "ec2-key"
    public_key = tls_private_key.ec2-key.public_key_openssh
}

resource "aws_security_group" "allow_ssh_http" {
    name = "allow_ssh_http"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["099720109477"]
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
    filter {
    name   = "virtualization-type"
    values = ["hvm"]
    }
}

resource "aws_instance" "terraform-test" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    key_name = aws_key_pair.ec2-key.key_name
    root_block_device {
      delete_on_termination = true
      volume_size = 8
      volume_type = "gp2"
    }
    associate_public_ip_address = true
    user_data = templatefile("${path.module}/ec2-user-data.sh",{})
    vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]   
    tags = {
        Name = "terraform-ec2"
    }
}

resource "local_file" "private_key" {
  content  = tls_private_key.ec2-key.private_key_pem
  filename = "${path.module}/ec2-key.pem"
  file_permission = "0600"
}