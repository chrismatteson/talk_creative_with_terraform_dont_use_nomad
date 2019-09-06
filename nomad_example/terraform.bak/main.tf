provider "aws" {
  region = "us-east-1"
}

resource "random_id" "project_name" {
  byte_length = 3
}

# Local for tag to attach to all items
locals {
  tags = merge(var.tags, {"ProjectName" = random_id.project_name.hex})
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = random_id.project_name.hex

  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  assign_generated_ipv6_cidr_block = true

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Name = "overridden-name-public"
  }

  tags = local.tags
}

# Lookup most recent AMI
data "aws_ami" "latest-image" {
  most_recent = true
  owners      = var.ami_filter_owners

  filter {
    name   = "name"
    values = var.ami_filter_name
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_configuration" "nomad_asg" {
  name_prefix          = random_id.project_name.hex
  image_id             = data.aws_ami.latest-image.id
  instance_type        = "t2.micro" 
  iam_instance_profile = aws_iam_instance_profile.cluster_server.id
  security_groups      = [aws_security_group.nomad_cluster_int.id]
  key_name             = "${var.ssh_key_name}"
  user_data            = templatefile("${path.module}/user_data.tpl", {})
}

resource "aws_autoscaling_group" "nomad_asg" {
  name_prefix          = random_id.project_name.hex
  launch_configuration = aws_launch_configuration.nomad_asg.name
  availability_zones   = module.vpc.azs
  vpc_zone_identifier  = module.vpc.intra_subnets

  min_size             = var.cluster_size
  max_size             = var.cluster_size
  desired_capacity     = var.cluster_size
#  termination_policies = ["${var.termination_policies}"]

  health_check_type         = "EC2"
#  health_check_grace_period = "${var.health_check_grace_period}"
#  wait_for_capacity_timeout = "${var.wait_for_capacity_timeout}"

#  enabled_metrics = ["${var.enabled_metrics}"]

  lifecycle {
    create_before_destroy = true
  }

#  tags = [local.tags]
}

# Create a new load balancer attachment for ASG if ASG is used
resource "aws_autoscaling_attachment" "asg_attachment_nomad" {
  autoscaling_group_name = "${aws_autoscaling_group.nomad_asg.id}"
  elb                    = "${aws_elb.nomad_elb.id}"
}

# Setup ELB
resource "aws_elb" "nomad_elb" {
  name_prefix                 = random_id.project_name.hex
  security_groups             = [aws_security_group.elb_sg.id]
  availability_zones          = module.vpc.azs
#  subnets                     = module.vpc.intra_subnets

  listener {
    lb_port           = "4646"
    lb_protocol       = "TCP"
    instance_port     = "4646"
    instance_protocol = "TCP"
  }

  listener {
    lb_port           = 8201
    lb_protocol       = "TCP"
    instance_port     = 8201
    instance_protocol = "TCP"
  }

#  health_check {
#    target              = "${var.health_check_protocol}:${var.nomad_api_port}${var.health_check_path}"
#    interval            = "${var.health_check_interval}"
#    healthy_threshold   = "${var.health_check_healthy_threshold}"
#    unhealthy_threshold = "${var.health_check_unhealthy_threshold}"
#    timeout             = "${var.health_check_timeout}"
#  }
}

# Setup IAM policies
resource "aws_iam_instance_profile" "cluster_server" {
  name = "${random_id.project_name.hex}-cluster-server"
  role = "${aws_iam_role.cluster_server_role.name}"
}

resource "aws_iam_role" "cluster_server_role" {
  name               = "${random_id.project_name.hex}-cluster-server"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version":"2008-10-17",
  "Statement":[
    {
      "Action":"sts:AssumeRole",
        "Principal":{
          "Service":[
            "ec2.amazonaws.com"
          ]
        },
      "Effect":"Allow",
        "Sid":""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "cluster_server" {
  name   = "${random_id.project_name.hex}-cluster-server"
  role   = "${aws_iam_role.cluster_server_role.id}"
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Action":[
        "ec2:DescribeInstances",
        "ec2:DescribeTags",
        "cloudwatch:PutMetricData",
                "cloudwatch:PutMetricAlarm",
                "sns:Publish",
                "ec2messages:GetMessages",
                "autoscaling:DescribeAutoScalingGroups"
            ],
            "Resource":"*"
        }
    ]
}
EOF
}

# Security Groups
resource "aws_security_group" "nomad_cluster_int" {
  name        = "nomad_cluster_int"
  description = "The SG for Nomad Servers Internal comms"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "nomad_cluster_allow_elb_820x_tcp" {
  type                     = "ingress"
  from_port                = 8200
  to_port                  = 8201
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.elb_sg.id}"
  description              = "Vault API port between elb and servers"
  security_group_id        = "${aws_security_group.nomad_cluster_int.id}"
}

resource "aws_security_group_rule" "nomad_cluster_allow_self_7300-7302_tcp" {
  type              = "ingress"
  from_port         = 7300
  to_port           = 7302
  protocol          = "tcp"
  self              = true
  description       = "Consul gossip protocol between agents and servers"
  security_group_id = "${aws_security_group.nomad_cluster_int.id}"
}

resource "aws_security_group_rule" "nomad_cluster_allow_self_7301-7302_udp" {
  type              = "ingress"
  from_port         = 7301
  to_port           = 7302
  protocol          = "udp"
  self              = true
  description       = "Consul gossip protocol between agents and servers"
  security_group_id = "${aws_security_group.nomad_cluster_int.id}"
}

resource "aws_security_group_rule" "nomad_cluster_allow_self_8200_tcp" {
  type              = "ingress"
  from_port         = 8200
  to_port           = 8200
  protocol          = "tcp"
  self              = true
  description       = "Vault API port between agents and servers"
  security_group_id = "${aws_security_group.nomad_cluster_int.id}"
}

resource "aws_security_group_rule" "nomad_cluster_allow_self_8201_tcp" {
  type              = "ingress"
  from_port         = 8201
  to_port           = 8201
  protocol          = "tcp"
  self              = true
  description       = "Vault listen port between servers"
  security_group_id = "${aws_security_group.nomad_cluster_int.id}"
}

resource "aws_security_group_rule" "nomad_cluster_allow_self_7500_tcp" {
  type              = "ingress"
  from_port         = 7500
  to_port           = 7501
  protocol          = "tcp"
  self              = true
  description       = "Consul API port between agents and servers"
  security_group_id = "${aws_security_group.nomad_cluster_int.id}"
}

resource "aws_security_group_rule" "nomad_cluster_allow_self_7600_tcp" {
  type              = "ingress"
  from_port         = 7600
  to_port           = 7600
  protocol          = "tcp"
  self              = true
  description       = "Consul DNS port between agents and servers"
  security_group_id = "${aws_security_group.nomad_cluster_int.id}"
}

resource "aws_security_group_rule" "nomad_cluster_allow_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.nomad_cluster_int.id}"
}

resource "aws_security_group" "elb_sg" {
  description = "Enable nomad UI and API access to the elb"
  name        = "elb-security-group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    protocol    = "tcp"
    from_port   = 8200
    to_port     = 8201
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

