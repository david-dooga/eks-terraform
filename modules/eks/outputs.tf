output "cluster_endpoint" {
    description = "Eks Cluster Endpoint"
    value       = aws_eks_cluster.main_eks_cluster.endpoint
}