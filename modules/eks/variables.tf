variable "region" {
    description = "AWS region"
    type        = string
}



variable "vpc_id" {
  description   = "My VPC ID for EKS Cluster"
  type          = string
}



variable "subnet_id" {
  description   = "subnet IDs"
  type          = list(string)
}



variable "eks_cluster_name" {
  description   = "My Cluster Name"
  type          = string
}



variable "cluster_version" {
  description   = "EKS Cluster Version"
  type          = string
}


variable "node_groups" {
    description = "Node Group Configuration"
    type = map(object({
      instance_types    = list(string)
      capacity_type     = string

      scaling_config    = object({
        desired_size    = number
        max_size        = number
        min_size        = number
      })
    }))
}
