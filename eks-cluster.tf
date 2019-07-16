##### VARIABLES #####
variable "access_to_eks_file" {
  description = "EKS policy file"
}

variable "eks_name" {
  description = "Name of EKS cluster"
}

variable "eks_version" {
  description = "EKS control plane version"
}

##### RESOURCES #####
resource "aws_iam_role" "eks-cluster" {
  name = "${local.name}_role_eks_control_plane"
  assume_role_policy = "${file(var.access_to_eks_file)}"
}
resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks-cluster.name}"
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks-cluster.name}"
}

resource "aws_security_group" "eks-cluster" {
  name        = "${local.name}_control_plane_sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.eks-cluster.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${local.tags}"
}

resource "aws_security_group_rule" "eks-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-cluster.id}"
  source_security_group_id = "${aws_security_group.eks-cluster-node.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_eks_cluster" "eks-cluster" {
  name     = "${local.eks_name}"
  role_arn = "${aws_iam_role.eks-cluster.arn}"
  version = "${var.eks_version}" 
  
  vpc_config {
    security_group_ids = ["${aws_security_group.eks-cluster.id}"]
    subnet_ids         = ["${aws_subnet.eks-cluster-private-subnet.0.id}","${aws_subnet.eks-cluster-private-subnet.1.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.eks-cluster-AmazonEKSServicePolicy",
  ]
}
