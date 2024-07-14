module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = local.name
  cidr                 = local.cidr_blocks
  enable_dns_hostnames = true
  enable_dns_support   = true

  azs            = data.aws_availability_zones.available.names
  public_subnets = ["10.2.0.0/24", "10.2.1.0/24", "10.2.2.0/24"]
  default_security_group_egress = [
    { cidr_blocks = "0.0.0.0/0" }
  ]
  default_security_group_ingress = [
    { cidr_blocks = local.cidr_blocks }
  ]
}
