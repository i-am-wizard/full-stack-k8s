module "eks" {
  source                 = "terraform-aws-modules/eks/aws"
  version                = "~> 21.0.0"
  name                   = var.cluster_name
  kubernetes_version     = "1.30"
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.public_subnets
  enable_irsa            = false
  endpoint_public_access = true
  eks_managed_node_groups = {
    default = {
      instance_types         = ["t3.medium"]
      desired_size           = 2
      min_size               = 1
      max_size               = 4
      capacity_type          = "ON_DEMAND"
      create_launch_template = true

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }
    }
  }
  addons = {
    coredns            = { most_recent = true }
    kube-proxy         = { most_recent = true }
    vpc-cni            = { before_compute = true, most_recent = true }
    aws-ebs-csi-driver = { 
      most_recent = true 
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }
}
