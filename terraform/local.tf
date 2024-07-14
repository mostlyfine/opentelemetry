data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name           = "otel"
  container_name = "lgtm"
  domain_name    = "mostlyfine.tech"
  cidr_blocks    = "10.2.0.0/16"

  grafana_port   = 3000
  otlp_grpc_port = 4317
  otlp_http_port = 4318
}
