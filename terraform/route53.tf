module "zones" {
  source = "terraform-aws-modules/route53/aws//modules/zones"

  zones = {
    "${local.domain_name}" = {
      comment = "Managed by Terraform"
    }
  }
}
