# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.lab_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster,
  ]

  tags = var.tags
}

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  tags = var.tags
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  # Uncomment if you created the key pair above
  # remote_access {
  #   ec2_ssh_key = aws_key_pair.main.key_name
  # }

  # depends_on = [
  #   aws_iam_role_policy_attachment.eks_worker_node_policy,
  #   aws_iam_role_policy_attachment.eks_cni_policy,
  #   aws_iam_role_policy_attachment.eks_container_registry_policy,
  # ]

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-node-group"
    }
  )
}

# Optional: EC2 Key Pair for SSH access
# Uncomment and update the path if you want SSH access to nodes
# resource "aws_key_pair" "main" {
#   key_name   = "${var.cluster_name}-key"
#   public_key = file("~/.ssh/id_rsa.pub")  # Update path to your public key
#   tags = var.tags
# }


resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"
}
