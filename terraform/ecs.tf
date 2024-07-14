locals {
  image = "grafana/otel-lgtm:latest"
  # image     = "${aws_ecr_repository.lgtm.repository_url}:latest"
}

resource "aws_ecr_repository" "lgtm" {
  name                 = local.name
  image_tag_mutability = "MUTABLE"
}

module "lgtm" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = local.name
  cluster_settings = [
    {
      name  = "containerInsights"
      value = "disabled"
    }
  ]

  services = {
    (local.name) = {
      cpu                               = 1024
      memory                            = 4096
      desired_count                     = 1
      health_check_grace_period_seconds = 30   # ALBがチェック開始するまでの猶予期間
      enable_execute_command            = true # readonlyだとagent餓鬼道せずecs-execできない

      create_task_exec_iam_role          = true
      task_exec_iam_role_name            = "${local.name}-task-exec-role"
      task_exec_iam_role_use_name_prefix = false

      create_tasks_iam_role          = true
      tasks_iam_role_name            = "${local.name}-task-role"
      tasks_iam_role_use_name_prefix = false

      # ecs-execするためのpolicy
      tasks_iam_role_statements = [
        {
          effect = "Allow"
          actions = [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel",
            "ssm:GetParametersByPath",
            "ssm:GetParameters",
            "ssm:GetParameter",
            "logs:PutLogEvents",
            "logs:CreateLogStream"
          ]
          resources = ["*"]
        }
      ]

      container_definitions = {
        (local.container_name) = {
          name                     = local.container_name
          image                    = local.image
          essential                = true
          readonly_root_filesystem = false

          port_mappings = [
            {
              name          = "grafana"
              containerPort = local.grafana_port
              hostPort      = local.grafana_port
              protocol      = "tcp"
            },
            {
              name          = "otel-grpc"
              containerPort = local.otlp_grpc_port
              hostPort      = local.otlp_grpc_port
              protocol      = "tcp"
            },
            {
              name          = "otel-http"
              containerPort = local.otlp_http_port
              hostPort      = local.otlp_http_port
              protocol      = "tcp"
            },
          ]

          mount_points = [
            {
              sourceVolume  = "fargate-efs"
              containerPath = "/data"
            }
          ]

          # health_check = {
          #   command = ["CMD-SHELL", "curl -sg 'http://localhost:9090/api/v1/query?query=up{job=\"opentelemetry-collector\"}' | jq -r .data.result[0].value[1] | grep '1' > /dev/null || exit 1"]
          # }

          enable_cloudwatch_logging              = true
          create_cloudwatch_log_group            = true
          cloudwatch_log_group_name              = "/aws/ecs/${local.name}/${local.container_name}"
          cloudwatch_log_group_retention_in_days = 7
        }
      }

      runtime_platform = {
        operating_system_family = "LINUX"
        cpu_architecture        = "X86_64"
      }

      volume = {
        vol-1 = {
          name = "fargate-efs"
          efs_volume_configuration = {
            file_system_id = module.efs.id
            root_directory = "/"
          }
        }
      }

      subnet_ids       = module.vpc.public_subnets
      assign_public_ip = true # dokcer hubからpullするためにpublic ipが必要

      security_group_rules = {
        alb_ingress_3000 = {
          type                     = "ingress"
          from_port                = local.grafana_port
          to_port                  = local.grafana_port
          protocol                 = "tcp"
          description              = "Grafana Service port"
          source_security_group_id = module.alb.security_group_id
        }
        ingress_otlp = {
          type        = "ingress"
          from_port   = local.otlp_grpc_port
          to_port     = local.otlp_http_port
          protocol    = "tcp"
          description = "OTLP port"
          cidr_blocks = [local.cidr_blocks]
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["grafana"].arn
          container_name   = local.container_name
          container_port   = local.grafana_port
        }
      }

      service_registries = {
        registry_arn = aws_service_discovery_service.lgtm.arn
      }
    }
  }
}

