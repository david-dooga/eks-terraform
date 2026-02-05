resource "aws_eks_cluster" "main_eks_cluster" {
  name      = var.eks_cluster_name
  role_arn  = aws_iam_role.eks_cluster_role.arn
  version   = var.cluster_version



  vpc_config {
    subnet_ids = var.subnet_id
  }



  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]
}





resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.eks_cluster_name}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}




resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
} 




# Worker Node iam role
resource "aws_iam_role" "eks_node_role" {
  name = "${var.eks_cluster_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}



resource "aws_iam_role_policy_attachment" "eks_node_policy" {
    for_each = toset([
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    ])

    policy_arn = each.value
    role = aws_iam_role.eks_node_role.name
}




resource "aws_eks_node_group" "example" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main_eks_cluster.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_id

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy
  ]
}



# 1. IAM Role for EBS CSI Driver (using Pod Identity Trust)


data "aws_iam_policy_document" "ebs_csi_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "ebs_csi_role" {
  name               = "${var.eks_cluster_name}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_trust.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_role.name
}


# 2. EKS Add-ons


# Required for Pod Identity to work
resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.main_eks_cluster.name
  addon_name   = "eks-pod-identity-agent"
}

# The EBS Driver itself
resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.main_eks_cluster.name
  addon_name   = "aws-ebs-csi-driver"
  # Ensures the agent is there before the driver tries to use it
  depends_on   = [aws_eks_addon.pod_identity]
}


# 3. Pod Identity Association (The "Bridge")

resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name    = aws_eks_cluster.main_eks_cluster.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa" # Default name created by the addon
  role_arn        = aws_iam_role.ebs_csi_role.arn
}
