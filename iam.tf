###### VARIABLES ######
variable "eks_users" {
  type = "list"
}
###### DATASOURCES #####
data "aws_iam_user" "eks-users" {
  count = "${length(var.eks_users)}"
  user_name = "${element(var.eks_users, count.index)}"
}
data "template_file" "user_arn" {
  count = "${length(var.eks_users)}"
  template = "${file("${path.module}/resources/templates/map_users.tpl")}"
  vars = {
    userarn = "${element(data.aws_iam_user.eks-users.*.arn, count.index)}" 
    username = "${element(data.aws_iam_user.eks-users.*.user_name, count.index)}"
  }
}
data "template_file" "config_map" {
  template = "${file("${path.module}/resources/templates/config_map.tpl")}"
  vars = {
    rolearn = "${aws_iam_role.eks-cluster-node.arn}"
    users = "${join("\n", data.template_file.user_arn.*.rendered) }"
  }
}