data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*tomcat*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["732788773938"] # Bitnami
}

data "aws_vpc" "default" {
  default = true
} 

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a","us-west-2b","us-west-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]


  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [module.blog_sg.id]

  tags = {
    Name = "HelloWorld"
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  name   = "blog_new"
  vpc_id = module.blog_vpc.vpc_id

  ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTP"
    }

    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTPS"
    }
  }

  egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4    = "0.0.0.0/0"
    }
  }
}