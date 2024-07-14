module "efs" {
  source = "terraform-aws-modules/efs/aws"

  name = "otel"

  # FYI: https://docs.aws.amazon.com/ja_jp/efs/latest/ug/performance.html#performancemodes
  throughput_mode = "elastic"

  enable_backup_policy = true

  # Mount targets
  mount_targets = { for k, v in zipmap(module.vpc.azs, module.vpc.public_subnets) : k => { subnet_id = v } }

  # TLS接続を強制するオプションがONだとECSでマウントできないため
  deny_nonsecure_transport = false

  # プライベート状態でないとアタッチできないオプションが有効になってしまうため
  attach_policy            = false

  ## TODO: これはプライベートでアクセスできるようにしたい


  # Security groups
  security_group_description = "Example EFS security group"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      description = "NFS ingress from VPC subnets"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }
}
