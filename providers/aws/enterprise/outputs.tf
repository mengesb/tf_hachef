# Outputs
output "chef_manage_url" {
  value = "https://${var.elb["hostname"]}.${var.domain}/organizations/${var.chef_org["short"]}"
}
output "chef_username" {
  value = "${var.chef_user["username"]}"
}
output "chef_user_password" {
  sensitive = true
  value = "${base64sha256(aws_instance.chef-frontends.0.id)}"
}
output "knife_rb" {
  value = ".chef/knife.rb"
}
