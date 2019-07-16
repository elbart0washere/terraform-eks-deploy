###### VARIABLES ######
variable "worker_nodes_ec2_instance_type" {
  description = "Instances type for worker nodes"
}
variable "worker_nodes_desired_capacity" {
  description = "Desired initial capacity for worker nodes ASG"
}     
variable "worker_nodes_max_size" {
  description = "Maximun size of worker nodes ASG"
}
variable "worker_nodes_min_size" {
  description = "Minimum size of worker nodes ASG"
}
variable "access_to_ec2_file" {
  description = "EC2 policy file"
}
variable "access_to_asg_file" {
  description = "ASG policy file"
}
variable "worker_nodes_ami_id" {
  default = "ami-0c24db5df6badc35a"
}

##### RESOURCES #####

#####IAM#####
resource "aws_iam_role" "eks-cluster-node" {
  name = "${local.name}_worker_nodes_role"
  assume_role_policy = "${file(var.access_to_ec2_file)}"
  #tags = "${local.tags}"
}
resource "aws_iam_policy" "asg-policy" {
  name = "${local.name}EKSAutoScaleGroupPolicy"
  policy = "${file(var.access_to_asg_file)}"
}
resource "aws_iam_role_policy_attachment" "eks-cluster-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.eks-cluster-node.name}"
}
resource "aws_iam_role_policy_attachment" "eks-cluster-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.eks-cluster-node.name}"
}
resource "aws_iam_role_policy_attachment" "eks-cluster-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.eks-cluster-node.name}"
}
resource "aws_iam_role_policy_attachment" "eks-cluster-node-asg-policy" {
  policy_arn = "${aws_iam_policy.asg-policy.arn}"
  role       = "${aws_iam_role.eks-cluster-node.name}"
}
resource "aws_iam_instance_profile" "eks-cluster-node" {
  name = "${local.name}_worker_nodes_role"
  role = "${aws_iam_role.eks-cluster-node.name}"
}
#####VPC#####
resource "aws_security_group" "eks-cluster-node" {
  name        = "${local.name}_worker_nodes_sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.eks-cluster.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }

  tags = "${local.tags}"
}
resource "aws_security_group_rule" "eks-cluster-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.eks-cluster-node.id}"
  source_security_group_id = "${aws_security_group.eks-cluster-node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-cluster-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 0
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-cluster-node.id}"
  source_security_group_id = "${aws_security_group.eks-cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}
# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html

#####ASG#####

locals {
  eks-cluster-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${local.eks_name}
USERDATA
}
resource "aws_launch_configuration" "eks-cluster" {
  name = "${local.name}_worker_node"
  associate_public_ip_address = false
  iam_instance_profile        = "${aws_iam_instance_profile.eks-cluster-node.name}"
  image_id                    = "${var.worker_nodes_ami_id}"
  instance_type               = "${var.worker_nodes_ec2_instance_type}"
  security_groups             = ["${aws_security_group.eks-cluster-node.id}"]
  user_data_base64            = "${base64encode(local.eks-cluster-node-userdata)}"
  key_name = "${var.key}"
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "eks-cluster" {
  desired_capacity     = "${var.worker_nodes_desired_capacity}"
  launch_configuration = "${aws_launch_configuration.eks-cluster.id}"
  max_size             = "${var.worker_nodes_max_size}"
  min_size             = "${var.worker_nodes_min_size}"
  name                 = "${local.name}_worker_nodes_asg"
  vpc_zone_identifier  = ["${aws_subnet.eks-cluster-private-subnet.0.id}","${aws_subnet.eks-cluster-private-subnet.1.id}"]  
  depends_on = ["aws_eks_cluster.eks-cluster"]
  tag {
    key                 = "Name"
    value               = "${local.eks_name}-eks-worker-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${local.eks_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "cluster-autoscaler"
    propagate_at_launch = true
  }  

  tag {
    key                 = "k8s.io/cluster-autoscaler/${local.eks_name}"
    value               = "cluster-autoscaler"
    propagate_at_launch = true
  }  

  tag {
    key                 = "kubernetes.io/role/internal-elb"
    value               = "true"
    propagate_at_launch = true
  }  
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = "${aws_autoscaling_group.eks-cluster.id}"
  alb_target_group_arn   = "${aws_lb_target_group.nlb.arn}"
}
