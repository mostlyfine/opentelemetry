module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name            = "${local.container_name}-alb"
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.public_alb_sg.security_group_id]

  access_logs = {
    bucket = module.public_alb_logs.s3_bucket_id
  }

  # For example only
  enable_deletion_protection = false

  listeners = {
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
      certificate_arn = module.acm.acm_certificate_arn
      fixed_response = {
        content_type = "text/plain"
        message_body = "Fixed message."
        status_code  = 200
      }
      rules = {
        grafana = {
          priority = 10
          actions = [
            {
              type             = "forward"
              target_group_key = "grafana"
            }
          ]
          conditions = [
            {
              host_header = {
                values = [
                  "grafana.${local.domain_name}"
                ]
              }
            }
          ]
        }
      }
    }
  }

  target_groups = {
    grafana = {
      name                              = "grafana"
      backend_protocol                  = "HTTP"
      backend_port                      = local.grafana_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        healthy_threshold = 2
        path              = "/login"
        port              = local.grafana_port
        interval          = 10
        timeout           = 5
      }
      create_attachment = false
    }
  }

  route53_records = {
    A = {
      name    = "grafana.${local.domain_name}"
      type    = "A"
      zone_id = module.zones.route53_zone_zone_id["${local.domain_name}"]
    }
  }
}

module "public_alb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name                = "${local.container_name}-alb"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp", "http-80-tcp"]
  egress_rules        = ["all-all"]
}

module "public_alb_logs" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket        = "${local.container_name}-alb-logs"
  acl           = "log-delivery-write"
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_elb_log_delivery_policy = true
  attach_lb_log_delivery_policy  = true
}

module "acm" {
  source = "terraform-aws-modules/acm/aws"

  domain_name               = local.domain_name
  zone_id                   = module.zones.route53_zone_zone_id["${local.domain_name}"]
  subject_alternative_names = ["*.${local.domain_name}"]
  validation_method         = "DNS"
  wait_for_validation       = true
}
