output "config_map_aws_auth" {
  value = "${data.template_file.config_map.rendered}"
}