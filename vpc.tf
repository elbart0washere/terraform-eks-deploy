##### VARIABLES #####
variable eks_public_subnets {
  type = "list"
  description = "EKS subnet selector"
}
variable eks_private_subnets {
  type = "list"
  description = "EKS subnet selector"
}
variable vpc_cidr {
  description = "VPC account cidr"
}
##### RESOURCES #####
resource "aws_vpc" "eks-cluster" {
 cidr_block = "${var.vpc_cidr}"
 enable_dns_hostnames = true
 enable_dns_support = true 
 tags = "${local.tags}"
}
resource "aws_subnet" "eks-cluster-public-subnet" {
  count = "${length(var.aws_azs)}"
  availability_zone = "${var.aws_region}${element(var.aws_azs,count.index)}"
  cidr_block  = "${element(var.eks_public_subnets,count.index)}"
  vpc_id      = "${aws_vpc.eks-cluster.id}"
  tags = "${local.tags}"
}
resource "aws_subnet" "eks-cluster-private-subnet" {
  count = "${length(var.aws_azs)}"
  availability_zone = "${var.aws_region}${element(var.aws_azs,count.index)}"
  cidr_block  = "${element(var.eks_private_subnets,count.index)}"
  vpc_id      = "${aws_vpc.eks-cluster.id}"
  tags = "${local.tags}"
}
resource "aws_internet_gateway" "eks-cluster" {
  vpc_id = "${aws_vpc.eks-cluster.id}"
  tags = "${local.tags}"
}
resource "aws_route_table" "eks-cluster" {
  vpc_id = "${aws_vpc.eks-cluster.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.eks-cluster.id}"
    }
  tags = "${local.tags}"

}
resource "aws_eip" "natgw-us-east-1a" {
  vpc      = true
  tags = "${local.tags}"
}
resource "aws_eip" "natgw-us-east-1b" {
  vpc      = true
  tags = "${local.tags}"
}
resource "aws_nat_gateway" "nat-gw-a" {
  allocation_id = "${aws_eip.natgw-us-east-1a.id}"
  subnet_id = "${aws_subnet.eks-cluster-public-subnet.0.id}"
  tags = "${local.tags}"
  depends_on = ["aws_subnet.eks-cluster-public-subnet"]
}
resource "aws_nat_gateway" "nat-gw-b" {
  allocation_id = "${aws_eip.natgw-us-east-1b.id}"
  subnet_id = "${aws_subnet.eks-cluster-public-subnet.1.id}"
  tags = "${local.tags}"
  depends_on = ["aws_subnet.eks-cluster-public-subnet"]
}
resource "aws_route_table" "eks-cluster-private-a" {
  vpc_id = "${aws_vpc.eks-cluster.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat-gw-a.id}"
  }
  tags = "${local.tags}"
}
resource "aws_route_table" "eks-cluster-private-b" {
  vpc_id = "${aws_vpc.eks-cluster.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat-gw-b.id}"
  }
  tags = "${local.tags}"
}
resource "aws_route_table_association" "eks-cluster-route_table_association_0" {
  subnet_id      = "${aws_subnet.eks-cluster-public-subnet.0.id}"
  route_table_id = "${aws_route_table.eks-cluster.id}"
}
resource "aws_route_table_association" "eks-cluster-route_table_association_1" {
  subnet_id      = "${aws_subnet.eks-cluster-public-subnet.1.id}"
  route_table_id = "${aws_route_table.eks-cluster.id}"
}
resource "aws_route_table_association" "eks-cluster-route_table_association_2" {
  subnet_id      = "${aws_subnet.eks-cluster-private-subnet.0.id}"
  route_table_id = "${aws_route_table.eks-cluster-private-a.id}"
}
resource "aws_route_table_association" "eks-cluster-route_table_association_3" {
  subnet_id      = "${aws_subnet.eks-cluster-private-subnet.1.id}"
  route_table_id = "${aws_route_table.eks-cluster-private-b.id}"
}