# EKS Cluster IAM Role - USING LAB ROLE INSTEAD
# resource "aws_iam_role" "eks_cluster" {
#   name = "${var.cluster_name}-cluster-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "eks.amazonaws.com"
#         }
#       }
#     ]
#   })
#
#   tags = var.tags
# }

# Use hardcoded LabRole ARN to avoid IAM GetRole permission issues in AWS Academy
locals {
  lab_role_arn = "arn:aws:iam::905418385450:role/LabRole"
}

# Attach AWS managed policy for EKS Cluster
# resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.eks_cluster.name
# }

# EKS Node Group IAM Role - USING LAB ROLE INSTEAD
# resource "aws_iam_role" "eks_nodes" {
#   name = "${var.cluster_name}-node-role"
#
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
#
#   tags = var.tags
# }

# Attach AWS managed policies for EKS Nodes
# resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.eks_nodes.name
# }
#
# resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.eks_nodes.name
# }
#
# resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.eks_nodes.name
# }
#
# # Additional IAM policy for CloudWatch Logs
# resource "aws_iam_role_policy_attachment" "eks_cloudwatch_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
#   role       = aws_iam_role.eks_nodes.name
# }

