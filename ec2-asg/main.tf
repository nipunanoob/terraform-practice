resource "tls_private_key" "ec2-key" {
    algorithm = "RSA"
}


resource "aws_key_pair" "ec2-key" {
    key_name = "ec2-key"
    public_key = tls_private_key.ec2-key.public_key_openssh
}

resource "aws_security_group" "terraform-alb-sg" {
    name = "terraform-alb-sg"
    ingress {
        from_port = 80
        to_port = 80
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

resource "aws_security_group" "allow_ssh_http" {
    name = "allow_ssh_http"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.terraform-alb-sg.id]
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

data "aws_iam_role" "EC2-role"{
    name = "IamRoleEC2"
}

resource "aws_iam_instance_profile" "test"{
    name = "Terraform_instance_profile"
    role = data.aws_iam_role.EC2-role.name
}

resource "aws_launch_template" "terraform-launch-template" {
    name = "terraform-launch-template"
    image_id = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    key_name = aws_key_pair.ec2-key.key_name
    vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]   
    user_data = base64encode(templatefile("${path.module}/ec2-user-data.sh",{}))
}

resource "aws_autoscaling_group" "terraform-asg"{
    name = "terraform-asg"
    max_size = 1
    min_size = 1
    vpc_zone_identifier = ["subnet-0da8da6005a4f9511", "subnet-0ca32209e0ccd9588"]
    target_group_arns = [aws_lb_target_group.terraform-target-group.arn]
    health_check_type = "ELB"
    health_check_grace_period  = 300

    launch_template {
        id = aws_launch_template.terraform-launch-template.id
    }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_lb_target_group" "terraform-target-group"{
    name = "terraform-target-group"
    port = 80
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id 
}

# resource "aws_lb_target_group_attachment" "attach_instance_1" {
#   target_group_arn = aws_lb_target_group.terraform-target-group.arn
#   target_id        = aws_instance.terraform-test.id
#   port             = 80
# }

# resource "aws_lb_target_group_attachment" "attach_instance_2" {
#   target_group_arn = aws_lb_target_group.terraform-target-group.arn
#   target_id        = aws_instance.terraform-test-2.id
#   port             = 80
# }


resource "aws_lb" "terraform-elb" {
    name = "terraform-elb"
    load_balancer_type = "application"
    security_groups = [aws_security_group.terraform-alb-sg.id]
    subnets = data.aws_subnets.default.ids
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.terraform-elb.arn
    port = 80
    protocol = "HTTP"

    default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-target-group.arn
    }

}

resource "local_file" "private_key" {
  content  = tls_private_key.ec2-key.private_key_pem
  filename = "${path.module}/ec2-key.pem"
  file_permission = "0600"
}
