#
# AWS Provider
#
provider "aws" {
  access_key = "${var.provider["access_key"]}"
  region     = "${var.provider["region"]}"
  secret_key = "${var.provider["secret_key"]}"
}
#
# AWS VPC setup
#
resource "aws_vpc" "chef-ha-vpc" {
  cidr_block           = "${var.vpc["cidr"]}"
  enable_dns_hostnames = "${var.vpc["dns_hostnames"]}"
  enable_dns_support   = "${var.vpc["dns_support"]}"
  instance_tenancy     = "${var.vpc["tenancy"]}"
  tags {
    Name               = "${var.vpc["tags_desc"]}"
  }
}
#
# AWS GW setup
#
resource "aws_internet_gateway" "chef-ha-gw" {
  vpc_id = "${aws_vpc.chef-ha-vpc.id}"
  tags {
    Name = "${var.gateway}"
  }
}
#
# AWS Subnet setup
#
resource "aws_subnet" "chef-ha-subnet" {
  count                   = "${length(keys(var.subnets))}"
  vpc_id                  = "${aws_vpc.chef-ha-vpc.id}"
  availability_zone       = "${element(keys(var.subnets), count.index)}"
  cidr_block              = "${element(values(var.subnets), count.index)}"
  map_public_ip_on_launch = "${lookup(var.subnets_public, element(keys(var.subnets), count.index))}"
  tags {
      Name                = "Chef HA Subnet ${element(values(var.subnets), count.index)} (${element(keys(var.subnets), count.index)})"
  }
}
#
# AWS Route Table setup
# Grant the VPC internet access on its main route table
resource "aws_route" "default_gateway" {
  route_table_id         = "${aws_vpc.chef-ha-vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.chef-ha-gw.id}"
}
#
# Associate subnets to main routing table
#
resource "aws_route_table_association" "subnet_routes" {
  count          = "${length(keys(var.subnets))}"
  subnet_id      = "${element(aws_subnet.chef-ha-subnet.*.id, count.index)}"
  route_table_id = "${aws_vpc.chef-ha-vpc.main_route_table_id}"
}
#
# AWS Route53 Zone Association
#
resource "aws_route53_zone_association" "chef-ha-vpc" {
  zone_id = "${var.r53_zones["internal"]}"
  vpc_id  = "${aws_vpc.chef-ha-vpc.id}"
}
#
# AWS Security Group setup - private services
# Chef Server AWS security group - https://docs.chef.io/server_firewalls_and_ports.html
resource "aws_security_group" "chef-ha-ssh" {
  name        = "${var.elb["hostname"]}.${var.domain} SSH SG"
  description = "${var.elb["hostname"]}.${var.domain} SSH SG"
  vpc_id      = "${aws_vpc.chef-ha-vpc.id}"
  tags {
    Name      = "${var.elb["hostname"]}.${var.domain} SSH SG"
  }
}
# SSH
resource "aws_security_group_rule" "chef-ha-ssh_22_tcp_restricted" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = "${var.ssh_cidrs}"
  security_group_id = "${aws_security_group.chef-ha-ssh.id}"
}
# Egress: ALL
resource "aws_security_group_rule" "chef-ha-ssh_allow_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.chef-ha-ssh.id}"
}
#
# AWS Security Group setup - public services
#
resource "aws_security_group" "chef-ha-frontend" {
  name        = "${var.elb["hostname"]}.${var.domain} Frontend SG"
  description = "${var.elb["hostname"]}.${var.domain} Frontend SG"
  vpc_id      = "${aws_vpc.chef-ha-vpc.id}"
  tags {
    Name      = "${var.elb["hostname"]}.${var.domain} Frontend SG"
  }
}
# HTTP (nginx)
resource "aws_security_group_rule" "chef-ha-frontend_80_tcp" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.chef-ha-frontend.id}"
}
# HTTPS (nginx)
resource "aws_security_group_rule" "chef-ha-frontend_443_tcp" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.chef-ha-frontend.id}"
}
# Egress: ALL
resource "aws_security_group_rule" "chef-ha-frontend_allow_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.chef-ha-frontend.id}"
}
#
# AWS Security Group setup - backend services
#
resource "aws_security_group" "chef-ha-backend" {
  name        = "${var.elb["hostname"]}.${var.domain} Backend SG"
  description = "${var.elb["hostname"]}.${var.domain} Backend SG"
  vpc_id      = "${aws_vpc.chef-ha-vpc.id}"
  tags {
    Name      = "${var.elb["hostname"]}.${var.domain} Backend SG"
  }
}
# inner security group communication
resource "aws_security_group_rule" "chef-ha-backend_sg_all" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.chef-ha-backend.id}"
  security_group_id        = "${aws_security_group.chef-ha-backend.id}"
}
# etcd
resource "aws_security_group_rule" "chef-ha-backend_2379_tcp" {
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2379
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.chef-ha-frontend.id}"
  security_group_id        = "${aws_security_group.chef-ha-backend.id}"
}
# postgresql
resource "aws_security_group_rule" "chef-ha-backend_5432_tcp" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.chef-ha-frontend.id}"
  security_group_id        = "${aws_security_group.chef-ha-backend.id}"
}
# leaderl
resource "aws_security_group_rule" "chef-ha-backend_7331_tcp" {
  type                     = "ingress"
  from_port                = 7331
  to_port                  = 7331
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.chef-ha-frontend.id}"
  security_group_id        = "${aws_security_group.chef-ha-backend.id}"
}
# elasticsearch
resource "aws_security_group_rule" "chef-ha-backend_9200_tcp" {
  type                     = "ingress"
  from_port                = 9200
  to_port                  = 9200
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.chef-ha-frontend.id}"
  security_group_id        = "${aws_security_group.chef-ha-backend.id}"
}
# Egress: ALL
resource "aws_security_group_rule" "chef-ha-backend_allow_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.chef-ha-backend.id}"
}
# Local prep
resource "null_resource" "chef-prep" {
  provisioner "local-exec" {
    command = <<-EOF
      rm -rf .chef && mkdir -p .chef
      openssl rand -base64 512 | tr -d '\r\n' > .chef/encrypted_data_bag_secret
      EOF
  }
}
# Chef provisiong backend attributes_json and dna.json templating
data "template_file" "backend-attributes-json" {
  count     = "${var.chef_backend["count"]}"
  template  = "${file("${path.module}/files/backend-attributes-json.tpl")}"
  vars {
    domain  = "${var.domain}"
    host    = "${format("%s-%03d", var.instance_hostname["backend"], count.index + 1)}"
  }
}
#
# Provision servers
# Backend: chef-backend
resource "aws_instance" "chef-backends" {
  count         = "${var.chef_backend["count"]}"
  ami           = "${lookup(var.ami, "${var.os}-${var.instance["backend_type"]}-${var.provider["region"]}")}"
  ebs_optimized = "${var.instance["ebs_optimized"]}"
  instance_type = "${var.instance["backend_flavor"]}"
  associate_public_ip_address = "${var.instance["backend_public"]}"
  subnet_id     = "${element(aws_subnet.chef-ha-subnet.*.id, count.index % length(keys(var.subnets)))}"
  vpc_security_group_ids = ["${aws_security_group.chef-ha-backend.id}","${aws_security_group.chef-ha-ssh.id}"]
  key_name      = "${var.instance_keys["key_name"]}"
  tags          = {
    Name        = "${format("%s-%03d.%s", var.instance_hostname["backend"], count.index + 1, var.domain)}"
    Description = "${var.instance["tags_desc"]}"
  }
  root_block_device {
    delete_on_termination = "${var.instance["backend_term"]}"
    volume_size = "${var.instance["backend_size"]}"
    volume_type = "${var.instance["backend_type"]}"
    iops        = "${var.instance["backend_iops"]}"
  }
  connection {
    host        = "${self.public_ip}"
    user        = "${var.ami_user[var.os]}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }
  # Setup
  provisioner "remote-exec" {
    script = "${path.module}/files/disable_firewall.sh"
  }
  # Setup instance storage
  provisioner "file" {
    source      = "${path.module}/files/instance_store.bash"
    destination = "/tmp/instance_store.bash"
  }
  provisioner "remote-exec" {
    inline = [
      "#!/usr/bin/env bash",
      "sudo chmod a+x /tmp/instance_store.bash",
      "sudo cp /etc/fstab /tmp/fstab.before",
      "sudo /tmp/instance_store.bash -d ${var.instance_store["device"]} -e ${var.instance_store["enabled"]} -f ${var.instance_store["filesystem"]} -m ${var.instance_store["mount"]} -o '${var.instance_store["mount_options"]}' -v",
      "cp /etc/fstab /tmp/fstab.after",
    ]
  }
  # Put cookbooks
  provisioner "remote-exec" {
    script = "${path.module}/files/chef-cookbooks.sh"
  }
  # Write dna.json for chef-solo run
  provisioner "remote-exec" {
    inline = [
      "cat > /tmp/dna.json <<EOF",
      "${element(data.template_file.backend-attributes-json.*.rendered, count.index)}",
      "EOF",
    ]
  }
  # Install requirements and run chef-solo
  provisioner "remote-exec" {
    inline = [
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v ${var.chef_client}",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-backend -d /tmp -v ${var.chef_backend["version"]}",
      "sudo chef-solo -j /tmp/dna.json -N ${self.tags.Name} -o 'recipe[system::default]'",
      "rm -rf /tmp/dna.json",
    ]
  }
  # Write the publish_address in /etc/chef-backend/chef-backend.rb
  provisioner "remote-exec" {
    inline = [
      "echo 'publish_address \"${self.private_ip}\"'|sudo tee -a /etc/chef-backend/chef-backend.rb",
    ]
  }
}
# Establish chef-backend cluster leader
resource "null_resource" "establish_leader" {
  count         = 1
  connection {
    host        = "${aws_instance.chef-backends.0.public_ip}"
    user        = "${var.ami_user[var.os]}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }
  provisioner "remote-exec" {
    inline = [
      "echo 'postgresql.md5_auth_cidr_addresses = [\"samehost\",\"samenet\",\"${var.vpc["cidr"]}\"]'|sudo tee -a /etc/chef-backend/chef-backend.rb",
      "sudo chef-backend-ctl create-cluster --accept-license --quiet -y",
    ]
  }
  # Setup for other backends to follow
  provisioner "remote-exec" {
    inline = [
      "sudo cp /etc/chef-backend/chef-backend-secrets.json /tmp/chef-backend-secrets.json",
      "sudo chown ${var.ami_user[var.os]} /tmp/chef-backend-secrets.json",
    ]
  }
  # Copy back file
  provisioner "local-exec" {
    command = "scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user[var.os]}@${element(aws_instance.chef-backends.*.public_ip, count.index)}:/tmp/chef-backend-secrets.json .chef/"
  }
  # Remove /tmp/chef-backend-secrets.json
  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /tmp/chef-backend-secrets.json",
    ]
  }
}
# Establish chef-backend cluster followers
resource "null_resource" "follow_leader" {
  count         = "${var.chef_backend["count"] - 1}"
  depends_on    = ["null_resource.establish_leader"]
  connection {
    host        = "${element(aws_instance.chef-backends.*.public_ip, count.index + 1)}"
    user        = "${var.ami_user[var.os]}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }
  provisioner "file" {
    source      = ".chef/chef-backend-secrets.json"
    destination = "/tmp/chef-backend-secrets.json"
  }
  # Establish cluster joining lock
  provisioner "local-exec" {
    command = "bash files/configuring.bash -f ${sha256(element(aws_instance.chef-backends.*.id, count.index + 1))}"
  }
  # Join cluster
  provisioner "remote-exec" {
    inline = [
      "echo 'postgresql.md5_auth_cidr_addresses = [\"samehost\",\"samenet\",\"${var.vpc["cidr"]}\"]'|sudo tee -a /etc/chef-backend/chef-backend.rb",
      "sudo chef-backend-ctl join-cluster ${aws_instance.chef-backends.0.private_ip} --accept-license --quiet -s /tmp/chef-backend-secrets.json -y",
      "[ $? -eq 0 ] && rm -rf /tmp/chef-backend-secrets.json",
    ]
  }
  # Release cluster joining lock
  provisioner "local-exec" {
    command = "rm -f /tmp/configuring.${sha256(element(aws_instance.chef-backends.*.id, count.index + 1))}"
  }
}
data "template_file" "etcd_settings" {
  count = "${length(var.etcd_settings)}"
  template = "${file("${path.module}/files/etcd_template.bash.tpl")}"
  vars {
    path = "${var.etcd_path}"
    file = "${element(keys(var.etcd_settings), count.index)}"
    input = "${element(values(var.etcd_settings), count.index)}"
  }
}
resource "null_resource" "etcd_files" {
  count = "${length(var.etcd_settings)}"
  provisioner "local-exec" {
    command = <<-EOC
      mkdir -p etcd_configs
      [ -f etcd_configs/etcd_config.${count.index}.bash ] && rm -f etcd_configs/etcd_config.${count.index}.bash
      tee etcd_configs/etcd_config.${count.index}.bash <<EOF
      ${element(data.template_file.etcd_settings.*.rendered, count.index)}
      EOF
      EOC
  }
}
resource "null_resource" "etcd_configure" {
  depends_on = ["null_resource.establish_leader","null_resource.follow_leader","null_resource.etcd_files"]
  count = "${var.chef_backend["count"]}"
  connection {
    host        = "${element(aws_instance.chef-backends.*.public_ip, count.index)}"
    user        = "${var.ami_user[var.os]}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }
  provisioner "file" {
    source      = "etcd_configs"
    destination = "/tmp/"
  }
  provisioner "remote-exec" {
    inline = [
      "for F in $(ls /tmp/etcd_configs); do bash /tmp/etcd_configs/$F; done",
    ]
  }
}
resource "null_resource" "etcd_restart" {
  depends_on = ["null_resource.etcd_configure"]
  count = "${var.chef_backend["count"]}"
  connection {
    host        = "${element(aws_instance.chef-backends.*.public_ip, count.index % var.chef_backend["count"])}"
    user        = "${var.ami_user[var.os]}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }
  provisioner "remote-exec" {
    inline = [
      "${var.etcd_restart_cmd}"
    ]
  }
}
resource "aws_route53_record" "chef-backends-private" {
  count   = "${var.chef_backend["count"]}"
  zone_id = "${var.r53_zones["internal"]}"
  name    = "${element(aws_instance.chef-backends.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.r53_ttls["internal"]}"
  records = ["${element(aws_instance.chef-backends.*.private_ip, count.index)}"]
}
resource "aws_route53_record" "chef-backends-public" {
  count   = "${var.chef_backend["count"]}"
  zone_id = "${var.r53_zones["external"]}"
  name    = "${element(aws_instance.chef-backends.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.r53_ttls["external"]}"
  records = ["${element(aws_instance.chef-backends.*.public_ip, count.index)}"]
}
#
# Frontend: chef-server-core
# Chef provisiong frontend attributes_json and dna.json templating
data "template_file" "frontend-attributes-json" {
  count      = "${var.chef_server["count"]}"
  template   = "${file("${path.module}/files/frontend-attributes-json.tpl")}"
  vars {
    domain   = "${var.domain}"
    host     = "${format("%s-%03d", var.instance_hostname["frontend"], count.index + 1)}"
  }
}
resource "aws_instance" "chef-frontends" {
  count         = "${var.chef_server["count"]}"
  ami           = "${lookup(var.ami, "${var.os}-${var.instance["frontend_type"]}-${var.provider["region"]}")}"
  ebs_optimized = "${var.instance["ebs_optimized"]}"
  instance_type = "${var.instance["frontend_flavor"]}"
  associate_public_ip_address = "${var.instance["frontend_public"]}"
  subnet_id     = "${element(aws_subnet.chef-ha-subnet.*.id, count.index % length(keys(var.subnets)))}"
  vpc_security_group_ids = ["${aws_security_group.chef-ha-frontend.id}","${aws_security_group.chef-ha-ssh.id}"]
  key_name      = "${var.instance_keys["key_name"]}"
  tags          = {
    Name        = "${format("%s-%03d.%s", var.instance_hostname["frontend"], count.index + 1, var.domain)}"
    Description = "${var.instance["tags_desc"]}"
  }
  root_block_device {
    delete_on_termination = "${var.instance["frontend_term"]}"
    volume_size = "${var.instance["frontend_size"]}"
    volume_type = "${var.instance["frontend_type"]}"
    iops        = "${var.instance["frontend_iops"]}"
  }
  connection {
    host        = "${self.public_ip}"
    user        = "${var.ami_user[var.os]}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }
  # Setup
  provisioner "remote-exec" {
    script = "${path.module}/files/disable_firewall.sh"
  }
  # Put cookbooks
  provisioner "remote-exec" {
    script = "${path.module}/files/chef-cookbooks.sh"
  }
  # Put certificate key
  provisioner "file" {
    source      = "${var.ssl_certificate["key_file"]}"
    destination = "/tmp/${var.elb["hostname"]}.${var.domain}.key"
  }
  # Put certificate
  provisioner "file" {
    source      = "${var.ssl_certificate["cert_file"]}"
    destination = "/tmp/${var.elb["hostname"]}.${var.domain}.crt"
  }
  # Write dna.json for chef-solo run
  provisioner "remote-exec" {
    inline = [
      "cat > /tmp/dna.json <<EOF",
      "${element(data.template_file.frontend-attributes-json.*.rendered, count.index)}",
      "EOF",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/opscode /var/opt/opscode/nginx/ca/ /var/opt/chef-manage",
      "sudo touch /var/opt/chef-manage/.license.accepted",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v ${var.chef_client}",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-server -d /tmp -v ${var.chef_server["version"]}",
      "sudo chef-solo -j /tmp/dna.json -N ${self.tags.Name} -o 'recipe[system::default]'",
      "[ $? -eq 0 ] && rm -f /tmp/dna.json",
    ]
  }
}
resource "aws_route53_record" "chef-frontend-private" {
  count   = "${var.chef_server["count"]}"
  zone_id = "${var.r53_zones["internal"]}"
  name    = "${element(aws_instance.chef-frontends.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.r53_ttls["internal"]}"
  records = ["${element(aws_instance.chef-frontends.*.private_ip, count.index)}"]
}
resource "aws_route53_record" "chef-frontend-public" {
  count   = "${var.chef_server["count"]}"
  zone_id = "${var.r53_zones["external"]}"
  name    = "${element(aws_instance.chef-frontends.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.r53_ttls["external"]}"
  records = ["${element(aws_instance.chef-frontends.*.public_ip, count.index)}"]
}
resource "null_resource" "generate_frontend_cfg" {
  depends_on    = ["null_resource.follow_leader"]
  count         = "${var.chef_server["count"]}"
  connection {
    host        = "${aws_instance.chef-backends.0.public_ip}"
    user        = "${var.ami_user[var.os]}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }
  # Generate chef server configuration
  provisioner "remote-exec" {
    inline = [
      "sudo chef-backend-ctl gen-server-config ${element(aws_instance.chef-frontends.*.tags.Name, count.index)} > /tmp/chef-server.rb.${sha256(element(aws_instance.chef-frontends.*.tags.Name, count.index))}",
      "sudo chown ${var.ami_user[var.os]} /tmp/chef-server.rb.${sha256(element(aws_instance.chef-frontends.*.tags.Name, count.index))}",
      "echo \"api_fqdn ${format("'%s.%s'", var.elb["hostname"], var.domain)}\" > file.out",
      "sed -i '/fqdn/ r file.out' /tmp/chef-server.rb.${sha256(element(aws_instance.chef-frontends.*.tags.Name, count.index))}",
      "rm -f file.out",
    ]
  }
  # Get generated configuration file
  provisioner "local-exec" {
    command = "scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user[var.os]}@${aws_instance.chef-backends.0.public_ip}:/tmp/chef-server.rb.${sha256(element(aws_instance.chef-frontends.*.tags.Name, count.index))} .chef/"
  }
  # Delete chef frontend configuration
  provisioner "remote-exec" {
    connection {
      host        = "${aws_instance.chef-backends.0.public_ip}"
      user        = "${var.ami_user[var.os]}"
      private_key = "${file("${var.instance_keys["key_file"]}")}"
    }
    inline = [
      "sudo rm -f /tmp/chef-server.rb.${sha256(element(aws_instance.chef-frontends.*.tags.Name, count.index))}",
    ]
  }
  # Put chef-server.rb on frontend
  provisioner "file" {
    connection {
      host        = "${element(aws_instance.chef-frontends.*.public_ip, count.index)}"
      user        = "${var.ami_user[var.os]}"
      private_key = "${file("${var.instance_keys["key_file"]}")}"
    }
    source      = ".chef/chef-server.rb.${sha256(element(aws_instance.chef-frontends.*.tags.Name, count.index))}"
    destination = "/tmp/chef-server.rb.${sha256(element(aws_instance.chef-frontends.*.tags.Name, count.index))}"
  }
}
resource "null_resource" "first_frontend" {
  count         = 1
  depends_on    = ["null_resource.generate_frontend_cfg"]
  connection {
    host        = "${element(aws_instance.chef-frontends.*.public_ip, count.index)}"
    user        = "${var.ami_user[var.os]}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/chef-server.rb.* /etc/opscode/chef-server.rb",
      "sudo mv /tmp/${var.elb["hostname"]}.${var.domain}.key /var/opt/opscode/nginx/ca/",
      "sudo mv /tmp/${var.elb["hostname"]}.${var.domain}.crt /var/opt/opscode/nginx/ca/",
      "sudo chown -R root:root /etc/opscode /var/opt/opscode",
      "sudo chef-server-ctl reconfigure",
      "sudo chef-server-ctl install chef-manage",
      "sudo chef-manage-ctl reconfigure",
      "sudo cp /etc/opscode/private-chef-secrets.json /etc/opscode/webui_priv.pem /etc/opscode/webui_pub.pem /etc/opscode/pivotal.pem /var/opt/opscode/upgrades/migration-level /tmp",
      "cd /tmp && sudo tar -czf chef-frontend.tgz migration-level private-chef-secrets.json webui_priv.pem webui_pub.pem pivotal.pem",
      "sudo chown ${var.ami_user[var.os]} /tmp/chef-frontend.tgz",
    ]
  }
  provisioner "local-exec" {
    command = "scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user[var.os]}@${element(aws_instance.chef-frontends.*.public_ip, count.index)}:/tmp/chef-frontend.tgz .chef/chef-frontend.tgz"
  }
}
resource "null_resource" "other_frontends" {
  count         = "${var.chef_server["count"] - 1}"
  depends_on    = ["null_resource.first_frontend"]
  connection {
    host        = "${element(aws_instance.chef-frontends.*.public_ip, count.index + 1)}"
    user        = "${var.ami_user[var.os]}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }
  # Put chef-frontend.tgz
  provisioner "file" {
    source      = ".chef/chef-frontend.tgz"
    destination = "/tmp/chef-frontend.tgz"
  }
  # TODO: Investigate replacing this with a remote-exec script
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/opscode /var/opt/opscode/nginx/ca /var/opt/opscode/upgrades /var/opt/chef-manage",
      "sudo touch /var/opt/chef-manage/.license.accepted",
      "sudo touch /var/opt/opscode/bootstrapped",
      "sudo mv /tmp/chef-server.rb.* /etc/opscode/chef-server.rb",
      "sudo mv /tmp/${var.elb["hostname"]}.${var.domain}.key /var/opt/opscode/nginx/ca/",
      "sudo mv /tmp/${var.elb["hostname"]}.${var.domain}.crt /var/opt/opscode/nginx/ca/",
      "sudo tar -xf /tmp/chef-frontend.tgz -C /etc/opscode",
      "sudo rm -f /tmp/chef-frontend.tgz",
      "sudo mv /etc/opscode/migration-level /var/opt/opscode/upgrades/migration-level",
      "sudo chown -R root:root /etc/opscode /var/opt/opscode /var/opt/chef-manage",
      "sudo chef-server-ctl reconfigure",
      "sudo chef-server-ctl install chef-manage",
      "sudo chef-manage-ctl reconfigure",
    ]
  }
}
resource "aws_route53_record" "chef-ha-elb" {
  zone_id = "${var.r53_zones["external"]}"
  name    = "${var.elb["hostname"]}.${var.domain}"
  type    = "CNAME"
  ttl     = "${var.r53_ttls["external"]}"
  records = ["${aws_elb.chef-ha-frontend.dns_name}"]
}
# knife.rb templating
data "template_file" "knife-rb" {
  depends_on = ["null_resource.chef-prep"]
  template = "${file("${path.module}/files/knife-rb.tpl")}"
  vars {
    user   = "${var.chef_user["username"]}"
    fqdn   = "${var.elb["hostname"]}.${var.domain}"
    org    = "${var.chef_org["short"]}"
  }
}
# Setting up Chef Server
resource "null_resource" "chef-setup" {
  depends_on    = ["null_resource.first_frontend"]
  connection {
    host        = "${aws_instance.chef-frontends.0.public_ip}"
    user        = "${var.ami_user[var.os]}"
    private_key = "${file("${var.instance_keys["key_file"]}")}"
  }
  # TODO: Maybe create parametertized script to run these commands (wrapping chef-server-ctl)
  provisioner "remote-exec" {
    inline = [
      "sudo chef-server-ctl user-create ${var.chef_user["username"]} ${var.chef_user["first_name"]} ${var.chef_user["last_name"]} ${var.chef_user["email"]} ${base64sha256(aws_instance.chef-frontends.0.id)} -f /tmp/${var.chef_user["username"]}.pem",
      "sudo chef-server-ctl org-create ${var.chef_org["short"]} '${var.chef_org["long"]}' --association_user ${var.chef_user["username"]} --filename /tmp/${var.chef_org["short"]}-validator.pem",
      "sudo chown ${var.ami_user[var.os]} /tmp/${var.chef_user["username"]}.pem /tmp/${var.chef_org["short"]}-validator.pem",
    ]
  }
  # Copy back files
  provisioner "local-exec" {
    command = <<-EOC
      rm -f .chef/${var.chef_org["short"]}-validator.pem .chef/${var.chef_user["username"]}.pem
      scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user[var.os]}@${aws_instance.chef-frontends.0.public_ip}:/tmp/${var.chef_org["short"]}-validator.pem .chef/${var.chef_org["short"]}-validator.pem
      scp -r -o stricthostkeychecking=no -i ${var.instance_keys["key_file"]} ${var.ami_user[var.os]}@${aws_instance.chef-frontends.0.public_ip}:/tmp/${var.chef_user["username"]}.pem .chef/${var.chef_user["username"]}.pem
      EOC
  }
}
#
# AWS ELB Setup
#
resource "aws_elb" "chef-ha-frontend" {
  name                  = "${var.elb["tf_resource_name"]}"
  #access_logs {
  #}
  #availability_zones   = ["${join(",",aws_subnet.chef-ha-subnet.*.availability_zone)}"]
  security_groups       = ["${aws_security_group.chef-ha-frontend.id}"]
  subnets               = ["${aws_subnet.chef-ha-subnet.*.id}"]
  instances             = ["${aws_instance.chef-frontends.*.id}"]
  internal              = false
  listener {
    instance_port       = 80
    instance_protocol   = "http"
    lb_port             = 80
    lb_protocol         = "http"
  }
  listener {
    instance_port       = 443
    instance_protocol   = "https"
    lb_port             = 443
    lb_protocol         = "https"
    ssl_certificate_id  = "${var.elb["certificate"]}"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTPS:443/login"
    interval            = 30
  }
  cross_zone_load_balancing = true
  idle_timeout          = 60
  connection_draining   = true
  connection_draining_timeout = 60
  tags {
    Name = "${var.elb["hostname"]}.${var.domain} Frontend ELB"
  }
}
resource "aws_app_cookie_stickiness_policy" "chef-manage" {
  name          = "chef-manage-cookie"
  load_balancer = "${aws_elb.chef-ha-frontend.id}"
  lb_port       = 443
  cookie_name   = "chef-manage"
}
resource "null_resource" "knife-rb" {
  # Generate knife.rb
  provisioner "local-exec" {
    command = <<-EOC
      [ -f .chef/knife.rb ] && rm -rf .chef/knife.rb || echo OK
      tee .chef/knife.rb <<EOF
      ${data.template_file.knife-rb.rendered}
      EOF
      EOC
  }
}
