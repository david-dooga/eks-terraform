# variable "vpc_cidr"{
#     description = "VPC CIDR block"
#     type = string
# }


# variable "public_subnet_cidr" {
#     description = "public subnet CIDR block"
#     type = list(string)
# }


# variable "private_subnet_cidr" {
#     description = "private subnet CIDR block"
#     type = list(string)
# }


# variable "availability_zones" {
#     description = "Availability zones"
#     type = list(string)
# }


# variable "eks_cluster_name" {
#     description = "Name of the EKS cluster"
#     type = string
# }

# variable "region" {
#     description = "AWS region"
#     type = string
# }




# variable "cluster_version" {
#   description = "EKS Cluster Version"
#   type = string
# }


# variable "node_groups" {
#     description = "Node Group Configuration"
#     type = map(object({
#       instance_types = list(string)
#       capacity_type = string

#       scaling_config = object({
#         desired_size = number
#         max_size = number
#         min_size = number
#       })
#     }))
# }
