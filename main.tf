#
# AWS Provider
#
provider "aws" {
  access_key = "${lookup(var.aws_settings, "access_key")}"
  region     = "${lookup(var.aws_settings, "region")}"
  secret_key = "${lookup(var.aws_settings, "secret_key")}"
}
#
# AWS VPC setup
#
resource "aws_vpc" "chef-ha-vpc" {
  cidr_block           = "${lookup(var.aws_vpc, "cidr_block")}"
  enable_dns_hostnames = "${lookup(var.aws_vpc, "enable_dns_hostnames")}"
  enable_dns_support   = "${lookup(var.aws_vpc, "enable_dns_support")}"
  instance_tenancy     = "${lookup(var.aws_vpc, "instance_tenancy")}"
  tags {
    Name               = "${lookup(var.aws_vpc, "tags_name")}"
  }
}
#
# AWS Route53 Zone Association
#
resource "aws_route53_zone_association" "chef-ha-vpc" {
  zone_id = "${lookup(var.aws_route53, "internal")}"
  vpc_id  = "${aws_vpc.chef-ha-vpc.id}"
}
#
# AWS Subnet setup
#
resource "aws_subnet" "chef-ha-subnet" {
  count                   = "${length(keys(var.aws_subnets))}"
  vpc_id                  = "${aws_vpc.chef-ha-vpc.id}"
  availability_zone       = "${element(keys(var.aws_subnets), count.index)}"
  cidr_block              = "${element(values(var.aws_subnets), count.index)}"
  map_public_ip_on_launch = "${lookup(var.aws_subnet_map, element(keys(var.aws_subnets), count.index))}"
  tags {
      Name                = "Chef HA Subnet ${element(values(var.aws_subnets), count.index)} (${element(keys(var.aws_subnets), count.index)})"
  }
}
#
# AWS GW setup
#
resource "aws_internet_gateway" "chef-ha-gw" {
  vpc_id = "${aws_vpc.chef-ha-vpc.id}"
  tags {
    Name = "${lookup(var.aws_vpc, "tags_name")} GW"
  }
}
#
# AWS Route Table setup
#
# Grant the VPC internet access on its main route table
resource "aws_route" "default_gateway" {
  route_table_id         = "${aws_vpc.chef-ha-vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.chef-ha-gw.id}"
}
# Associate subnets to main routing table
resource "aws_route_table_association" "subnet_routes" {
  count          = "${length(keys(var.aws_subnets))}"
  subnet_id      = "${element(aws_subnet.chef-ha-subnet.*.id, count.index)}"
  route_table_id = "${aws_vpc.chef-ha-vpc.main_route_table_id}"
}
#
# AWS Security Group setup - private services
# Chef Server AWS security group - https://docs.chef.io/server_firewalls_and_ports.html
resource "aws_security_group" "chef-ha-ssh" {
  name        = "${var.hostname}.${var.domain} SSH SG"
  description = "${var.hostname}.${var.domain} SSH SG"
  vpc_id      = "${aws_vpc.chef-ha-vpc.id}"
  tags {
    Name      = "${var.hostname}.${var.domain} SSH SG"
  }
}
# SSH
resource "aws_security_group_rule" "chef-ha-ssh_22_tcp_restricted" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${split(",", var.allowed_cidrs)}"]
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
  name        = "${var.hostname}.${var.domain} Frontend SG"
  description = "${var.hostname}.${var.domain} Frontend SG"
  vpc_id      = "${aws_vpc.chef-ha-vpc.id}"
  tags {
    Name      = "${var.hostname}.${var.domain} Frontend SG"
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
  name        = "${var.hostname}.${var.domain} Backend SG"
  description = "${var.hostname}.${var.domain} Backend SG"
  vpc_id      = "${aws_vpc.chef-ha-vpc.id}"
  tags {
    Name      = "${var.hostname}.${var.domain} Backend SG"
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
#
# AWS ELB Setup
#
resource "aws_elb" "chef-ha-frontend" {
  name                  = "${var.hostname}-${replace(var.domain,".","-")}-ELB"
  #access_logs {
  #}
  #availability_zones   = ["${join(",",aws_subnet.chef-ha-subnet.*.availability_zone)}"]
  security_groups       = ["${aws_security_group.chef-ha-frontend.id}"]
  subnets               = ["${aws_subnet.chef-ha-subnet.*.id}"]
  instances             = ["${aws_instance.chef-frontend.id}","${aws_instance.chef-frontends.*.id}"]
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
    ssl_certificate_id  = "${var.aws_elb_certificate}"
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
    Name = "${var.hostname}.${var.domain} Frontend ELB"
  }
}
resource "aws_app_cookie_stickiness_policy" "chef-manage" {
  name          = "chef-manage-cookie"
  load_balancer = "${aws_elb.chef-ha-frontend.id}"
  lb_port       = 443
  cookie_name   = "chef-manage"
}
# Local prep
resource "null_resource" "chef-prep" {
  provisioner "local-exec" {
    command = <<-EOF
      rm -rf .chef && mkdir -p .chef
      openssl rand -base64 512 | tr -d '\r\n' > .chef/encrypted_data_bag_secret
      echo "Local prep complete"
      EOF
  }
}
# Chef provisiong attributes_json and dna.json templating
resource "template_file" "be-leader-attributes-json" {
  template  = "${file("${path.module}/files/leader-attributes-json.tpl")}"
  vars {
    domain  = "${var.domain}"
    host    = "${format("%s-%03d", var.be_hostname, count.index + 1)}"
    license = "${var.accept_license}"
    leader  = "true"
  }
}
# Chef provisiong attributes_json and dna.json templating
resource "template_file" "be-follower-attributes-json" {
  count     = "${length(keys(var.aws_subnets)) - 1}"
  template  = "${file("${path.module}/files/follower-attributes-json.tpl")}"
  vars {
    domain  = "${var.domain}"
    host    = "${format("%s-%03d", var.be_hostname, count.index + 2)}"
    license = "${var.accept_license}"
    leader  = "${aws_instance.chef-backend.private_ip}"
    secrets = "/tmp/chef-backend-secrets.json"
  }
}
#
# Provision servers
# Backend: chef-backend
resource "aws_instance" "chef-backend" {
  ami           = "${lookup(var.ami_map, "${var.ami_os}-${lookup(var.aws_settings, "region")}")}"
  instance_type = "${var.aws_flavor}"
  associate_public_ip_address = "${var.public_ip}"
  subnet_id     = "${aws_subnet.chef-ha-subnet.0.id}"
  vpc_security_group_ids = ["${aws_security_group.chef-ha-backend.id}","${aws_security_group.chef-ha-ssh.id}"]
  key_name      = "${var.aws_key_name}"
  tags          = {
    Name        = "${format("%s-%03d.%s", var.be_hostname, count.index + 1, var.domain)}"
    Description = "${var.tag_description}"
  }
  root_block_device {
    delete_on_termination = "${var.root_delete_termination}"
    volume_size = "${var.root_volume_size}"
    volume_type = "${var.root_volume_type}"
  }
  connection {
    host        = "${self.public_ip}"
    user        = "${lookup(var.ami_usermap, var.ami_os)}"
    private_key = "${var.aws_private_key_file}"
  }
  # Setup
  provisioner "remote-exec" {
    script = "${path.module}/files/disable_firewall.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /var/chef/cookbooks",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v ${var.chef_clientv}",
      "echo 'Version ${var.chef_clientv} of chef-client installed'"
    ]
  }
  # Get cookbooks
  provisioner "remote-exec" {
    script = "files/chef-cookbooks.sh"
  }
  # Put cookbook there
  provisioner "file" {
    source = "${path.module}/files/chef-backend"
    destination = "chef-backend"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv chef-backend /var/chef/cookbooks/chef-backend",
      "sudo chown -R root:root /var/chef/cookbooks"
    ]
  }
  # Write dna.json for chef-solo run
  provisioner "remote-exec" {
    inline = [
      "cat > /tmp/dna.json <<EOF",
      "${template_file.be-leader-attributes-json.rendered}",
      "EOF",
    ]
  }
  # Run chef-solo and get us a Chef server
  provisioner "remote-exec" {
    inline = [
      "sudo chef-solo -j /tmp/dna.json -N ${format("%s-%03d.%s", var.be_hostname, count.index, var.domain)} -o 'recipe[system::default],recipe[chef-backend::default]'",
      "rm /tmp/dna.json",
    ]
  }
  # Stage required file to copy back
  provisioner "remote-exec" {
    inline = [
      "sudo cp /etc/chef-backend/chef-backend-secrets.json /tmp/chef-backend-secrets.json",
      "sudo chown ${lookup(var.ami_usermap, var.ami_os)} /tmp/chef-backend-secrets.json",
    ]
  }
  # Really REALLY ugly hack
  # Per chef-backend developer; this will be removable when they fix a bug allowing for the following syntax to not break join-cluster:
  # postgresql.md5_auth_cidr_addresses = ["samehost", "samenet", "${lookup(var.aws_vpc, "cidr_block")}"]
  provisioner "remote-exec" {
    inline = [
      "echo 'host       all         all         ${lookup(var.aws_vpc, "cidr_block")} md5' | sudo tee -a /var/opt/chef-backend/postgresql/9.5/data/pg_hba.conf",
      "echo 'hostssl    replication replicator  ${lookup(var.aws_vpc, "cidr_block")} md5' | sudo tee -a /var/opt/chef-backend/postgresql/9.5/data/pg_hba.conf",
      "sudo chef-backend-ctl restart",
      "echo 'Added ${lookup(var.aws_vpc, "cidr_block")} to pg_hba.conf'",
    ]
  }
  # Copy back files
  provisioner "local-exec" {
    command = "scp -r -o stricthostkeychecking=no -i ${var.aws_private_key_file} ${lookup(var.ami_usermap, var.ami_os)}@${self.public_ip}:/tmp/chef-backend-secrets.json .chef/chef-backend-secrets.json"
  }
}
resource "aws_route53_record" "chef-backend-private" {
  count   = "1"
  zone_id = "${lookup(var.aws_route53, "internal")}"
  name    = "${aws_instance.chef-backend.tags.Name}"
  type    = "A"
  ttl     = "${var.route53_ttl}"
  records = ["${aws_instance.chef-backend.private_ip}"]
}
resource "aws_route53_record" "chef-backend-public" {
  count   = "1"
  zone_id = "${lookup(var.aws_route53, "external")}"
  name    = "${aws_instance.chef-backend.tags.Name}"
  type    = "A"
  ttl     = "${var.route53_ttl}"
  records = ["${aws_instance.chef-backend.public_ip}"]
}
module "chef-backend-secrets" {
  source = "github.com/mengesb/tf_filemodule"
  file   = ".chef/chef-backend-secrets.json"
}
resource "aws_instance" "chef-backends" {
  depends_on    = ["aws_instance.chef-backend"]
  count         = "${length(keys(var.aws_subnets)) - 1}"
  ami           = "${lookup(var.ami_map, "${var.ami_os}-${lookup(var.aws_settings, "region")}")}"
  instance_type = "${var.aws_flavor}"
  associate_public_ip_address = "${var.public_ip}"
  subnet_id     = "${element(aws_subnet.chef-ha-subnet.*.id, count.index + 1)}"
  vpc_security_group_ids = ["${aws_security_group.chef-ha-backend.id}","${aws_security_group.chef-ha-ssh.id}"]
  key_name      = "${var.aws_key_name}"
  tags          = {
    Name        = "${format("%s-%03d.%s", var.be_hostname, count.index + 2, var.domain)}"
    Description = "${var.tag_description}"
  }
  root_block_device {
    delete_on_termination = "${var.root_delete_termination}"
    volume_size = "${var.root_volume_size}"
    volume_type = "${var.root_volume_type}"
  }
  connection {
    host        = "${self.public_ip}"
    user        = "${lookup(var.ami_usermap, var.ami_os)}"
    private_key = "${var.aws_private_key_file}"
  }
  # Setup
  provisioner "remote-exec" {
    script = "${path.module}/files/disable_firewall.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v ${var.chef_clientv}",
      "echo 'Version ${var.chef_clientv} of chef-client installed'"
    ]
  }
  # Get cookbooks
  provisioner "remote-exec" {
    script = "files/chef-cookbooks.sh"
  }
  # Put cookbook there
  provisioner "file" {
    source      = "${path.module}/files/chef-backend"
    destination = "chef-backend"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv chef-backend /var/chef/cookbooks/chef-backend",
      "sudo chown -R root:root /var/chef/cookbooks"
    ]
  }
  provisioner "file" {
    source      = "${module.chef-backend-secrets.file}"
    destination = "/tmp/chef-backend-secrets.json"
  }
  # Write dna.json for chef-solo run
  provisioner "remote-exec" {
    inline = [
      "cat > /tmp/dna.json <<EOF",
      "${element(template_file.be-follower-attributes-json.*.rendered, count.index)}",
      "EOF",
    ]
  }
  # Establish cluster joining lock
  provisioner "local-exec" {
    command = "bash files/configuring.bash -f ${sha256(self.id)}"
  }
  # Run chef-solo and get us a Chef backend server
  provisioner "remote-exec" {
    inline = [
      "sudo chef-solo -j /tmp/dna.json -N ${format("%s-%03d.%s", var.be_hostname, count.index + 2, var.domain)} -o 'recipe[system::default],recipe[chef-backend::default]'",
      "rm -f /tmp/dna.json /tmp/chef-backend-secrets.json",
    ]
  }
  # Release cluster joining lock
  provisioner "local-exec" {
    command = "rm -f /tmp/configuring.${sha256(self.id)}"
  }
}
resource "aws_route53_record" "chef-backends-private" {
  count   = "${length(keys(var.aws_subnets)) - 1}"
  zone_id = "${lookup(var.aws_route53, "internal")}"
  name    = "${element(aws_instance.chef-backends.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.route53_ttl}"
  records = ["${element(aws_instance.chef-backends.*.private_ip, count.index)}"]
}
resource "aws_route53_record" "chef-backends-public" {
  count   = "${length(keys(var.aws_subnets)) - 1}"
  zone_id = "${lookup(var.aws_route53, "external")}"
  name    = "${element(aws_instance.chef-backends.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.route53_ttl}"
  records = ["${element(aws_instance.chef-backends.*.public_ip, count.index)}"]
}
#
# Frontend: chef-server-core
# Chef provisiong attributes_json and dna.json templating
resource "template_file" "frontend-attributes-json" {
  count      = "${length(keys(var.aws_subnets))}"
  template   = "${file("${path.module}/files/frontend-attributes-json.tpl")}"
  vars {
    domain   = "${var.domain}"
    host     = "${format("%s-%03d", var.fe_hostname, count.index + 1)}"
  }
}
resource "aws_instance" "chef-frontend" {
  depends_on    = ["aws_instance.chef-backend","aws_instance.chef-backends"]
  count         = "1"
  ami           = "${lookup(var.ami_map, "${var.ami_os}-${lookup(var.aws_settings, "region")}")}"
  instance_type = "${var.aws_flavor}"
  associate_public_ip_address = "${var.public_ip}"
  subnet_id     = "${element(aws_subnet.chef-ha-subnet.*.id, count.index + 1)}"
  vpc_security_group_ids = ["${aws_security_group.chef-ha-frontend.id}","${aws_security_group.chef-ha-ssh.id}"]
  key_name      = "${var.aws_key_name}"
  tags          = {
    Name        = "${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)}"
    Description = "${var.tag_description}"
  }
  root_block_device {
    delete_on_termination = "${var.root_delete_termination}"
    volume_size = "${var.root_volume_size}"
    volume_type = "${var.root_volume_type}"
  }
  connection {
    host        = "${self.public_ip}"
    user        = "${lookup(var.ami_usermap, var.ami_os)}"
    private_key = "${var.aws_private_key_file}"
  }
  # Create chef frontend configuration
  provisioner "remote-exec" {
    connection {
      host        = "${aws_instance.chef-backend.public_ip}"
      user        = "${lookup(var.ami_usermap, var.ami_os)}"
      private_key = "${var.aws_private_key_file}"
    }
    # TODO: Replace chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)} with chef-server.rb.${sha256(self.id)}
    inline = [
      "sudo chef-backend-ctl gen-server-config ${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)} > /tmp/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)}",
      "sudo chown ${lookup(var.ami_usermap, var.ami_os)} /tmp/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)}",
      "echo \"api_fqdn ${format("'%s.%s'", var.hostname, var.domain)}\" > file.out",
      "sed -i '/fqdn/ r file.out' /tmp/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)}",
      "rm -f file.out",
    ]
  }
  # Get generated configuration file
  # TODO: Replace chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)} with chef-server.rb.${sha256(self.id)}
  provisioner "local-exec" {
    command = "scp -r -o stricthostkeychecking=no -i ${var.aws_private_key_file} ${lookup(var.ami_usermap, var.ami_os)}@${aws_instance.chef-backend.public_ip}:/tmp/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)} .chef/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)}"
  }
  # Delete chef frontend configuration
  provisioner "remote-exec" {
    connection {
      host        = "${aws_instance.chef-backend.public_ip}"
      user        = "${lookup(var.ami_usermap, var.ami_os)}"
      private_key = "${var.aws_private_key_file}"
    }
    # TODO: Replace chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)} with chef-server.rb.${sha256(self.id)}
    inline = [
      "sudo rm -f /tmp/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)}",
    ]
  }
  # Setup
  provisioner "remote-exec" {
    script = "${path.module}/files/disable_firewall.sh"
  }
  provisioner "remote-exec" {
    script = "${path.module}/files/chef-server-cookbooks.sh"
  }
  # Write dna.json for chef-solo run
  provisioner "remote-exec" {
    inline = [
      "cat > /tmp/dna.json <<EOF",
      "${element(template_file.frontend-attributes-json.*.rendered, count.index)}",
      "EOF",
    ]
  }
  # Put certificate key
  provisioner "file" {
    source      = "${var.ssl_key}"
    destination = "/tmp/${var.hostname}.${var.domain}.key"
  }
  # Put certificate
  provisioner "file" {
    source      = "${var.ssl_cert}"
    destination = "/tmp/${var.hostname}.${var.domain}.crt"
  }
  # Put chef-server.rb
  provisioner "file" {
    source      = ".chef/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)}"
    destination = "/tmp/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)}"
  }
  # TODO: Investigate replacing this with a remote-exec script
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/opscode /var/opt/opscode/nginx/ca/",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v ${var.chef_clientv}",
      "echo 'Version ${var.chef_clientv} of chef-client installed'",
      "sudo chef-solo -j /tmp/dna.json -N ${format("%s-%03d.%s", var.be_hostname, count.index + 2, var.domain)} -o 'recipe[system::default]'",
      "sudo rm -f /tmp/dna.json",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-server -d /tmp -v ${var.chef_serverv}",
      "sudo mv /tmp/chef-server.rb.* /etc/opscode/chef-server.rb",
      "sudo mv /tmp/${var.hostname}.${var.domain}.key /var/opt/opscode/nginx/ca/",
      "sudo mv /tmp/${var.hostname}.${var.domain}.crt /var/opt/opscode/nginx/ca/",
      "sudo chown -R root:root /etc/opscode /var/opt/opscode",
      "sudo chef-server-ctl reconfigure",
      "sudo chef-server-ctl install chef-manage",
      "sudo mkdir -p /var/opt/chef-manage",
      "sudo touch /var/opt/chef-manage/.license.accepted",
      "sudo chef-manage-ctl reconfigure",
      "sudo cp /etc/opscode/private-chef-secrets.json /etc/opscode/webui_priv.pem /etc/opscode/webui_pub.pem /etc/opscode/pivotal.pem /var/opt/opscode/upgrades/migration-level /tmp",
      "cd /tmp && sudo tar -czf chef-frontend.tgz migration-level private-chef-secrets.json webui_priv.pem webui_pub.pem pivotal.pem",
      "sudo chown ${lookup(var.ami_usermap, var.ami_os)} /tmp/chef-frontend.tgz",
    ]
  }
  provisioner "local-exec" {
    command = "scp -r -o stricthostkeychecking=no -i ${var.aws_private_key_file} ${lookup(var.ami_usermap, var.ami_os)}@${self.public_ip}:/tmp/chef-frontend.tgz .chef/chef-frontend.tgz"
  }
}
resource "aws_route53_record" "chef-frontend-private" {
  count   = "1"
  zone_id = "${lookup(var.aws_route53, "internal")}"
  name    = "${aws_instance.chef-frontend.tags.Name}"
  type    = "A"
  ttl     = "${var.route53_ttl}"
  records = ["${aws_instance.chef-frontend.private_ip}"]
}
resource "aws_route53_record" "chef-frontend-public" {
  count   = "1"
  zone_id = "${lookup(var.aws_route53, "external")}"
  name    = "${aws_instance.chef-frontend.tags.Name}"
  type    = "A"
  ttl     = "${var.route53_ttl}"
  records = ["${aws_instance.chef-frontend.public_ip}"]
}
# Provision the rest of the frontends
resource "aws_instance" "chef-frontends" {
  depends_on    = ["aws_instance.chef-frontend"]
  count         = "${length(keys(var.aws_subnets)) - 1}"
  ami           = "${lookup(var.ami_map, "${var.ami_os}-${lookup(var.aws_settings, "region")}")}"
  instance_type = "${var.aws_flavor}"
  associate_public_ip_address = "${var.public_ip}"
  subnet_id     = "${element(aws_subnet.chef-ha-subnet.*.id, count.index + 2)}"
  vpc_security_group_ids = ["${aws_security_group.chef-ha-frontend.id}","${aws_security_group.chef-ha-ssh.id}"]
  key_name      = "${var.aws_key_name}"
  tags          = {
    Name        = "${format("%s-%03d.%s", var.fe_hostname, count.index + 2, var.domain)}"
    Description = "${var.tag_description}"
  }
  root_block_device {
    delete_on_termination = "${var.root_delete_termination}"
    volume_size = "${var.root_volume_size}"
    volume_type = "${var.root_volume_type}"
  }
  connection {
    host        = "${self.public_ip}"
    user        = "${lookup(var.ami_usermap, var.ami_os)}"
    private_key = "${var.aws_private_key_file}"
  }
  # Create chef frontend configuration
  provisioner "remote-exec" {
    connection {
      host        = "${aws_instance.chef-backend.public_ip}"
      user        = "${lookup(var.ami_usermap, var.ami_os)}"
      private_key = "${var.aws_private_key_file}"
    }
    # TODO: Replace chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)} with chef-server.rb.${sha256(self.id)}
    inline = [
      "sudo chef-backend-ctl gen-server-config ${format("%s-%03d.%s", var.fe_hostname, count.index + 2, var.domain)} > /tmp/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 2, var.domain)}",
      "sudo chown ${lookup(var.ami_usermap, var.ami_os)} /tmp/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 2, var.domain)}",
      "echo \"api_fqdn ${format("'%s.%s'", var.hostname, var.domain)}\" > file.out",
      "sed -i '/fqdn/ r file.out' /tmp/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 2, var.domain)}",
      "rm -f file.out",
    ]
  }
  # Get generated configuration file
  # TODO: Replace chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)} with chef-server.rb.${sha256(self.id)}
  provisioner "local-exec" {
    command = "scp -r -o stricthostkeychecking=no -i ${var.aws_private_key_file} ${lookup(var.ami_usermap, var.ami_os)}@${aws_instance.chef-backend.public_ip}:/tmp/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 2, var.domain)} .chef/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 2, var.domain)}"
  }
  # Delete chef frontend configuration
  provisioner "remote-exec" {
    connection {
      host        = "${aws_instance.chef-backend.public_ip}"
      user        = "${lookup(var.ami_usermap, var.ami_os)}"
      private_key = "${var.aws_private_key_file}"
    }
    # TODO: Replace chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)} with chef-server.rb.${sha256(self.id)}
    inline = [
      "sudo rm -f /tmp/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 2, var.domain)}",
    ]
  }
  # Setup
  provisioner "remote-exec" {
    script = "${path.module}/files/disable_firewall.sh"
  }
  provisioner "remote-exec" {
    script = "${path.module}/files/chef-server-cookbooks.sh"
  }
  # Write dna.json for chef-solo run
  provisioner "remote-exec" {
    inline = [
      "cat > /tmp/dna.json <<EOF",
      "${element(template_file.frontend-attributes-json.*.rendered, count.index + 1)}",
      "EOF",
    ]
  }
  # Put certificate key
  provisioner "file" {
    source      = "${var.ssl_key}"
    destination = "/tmp/${var.hostname}.${var.domain}.key"
  }
  # Put certificate
  provisioner "file" {
    source      = "${var.ssl_cert}"
    destination = "/tmp/${var.hostname}.${var.domain}.crt"
  }
  # Put chef-server.rb
  # TODO: Replace chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 1, var.domain)} with chef-server.rb.${sha256(self.id)}
  provisioner "file" {
    source      = ".chef/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 2, var.domain)}"
    destination = "/tmp/chef-server.rb.${format("%s-%03d.%s", var.fe_hostname, count.index + 2, var.domain)}"
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
      "sudo mv /tmp/${var.hostname}.${var.domain}.key /var/opt/opscode/nginx/ca/",
      "sudo mv /tmp/${var.hostname}.${var.domain}.crt /var/opt/opscode/nginx/ca/",
      "sudo tar -xf /tmp/chef-frontend.tgz -C /etc/opscode",
      "sudo rm -f /tmp/chef-frontend.tgz",
      "sudo mv /etc/opscode/migration-level /var/opt/opscode/upgrades/migration-level",
      "sudo chown -R root:root /etc/opscode /var/opt/opscode /var/opt/chef-manage",
      "###",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v ${var.chef_clientv}",
      "echo 'Version ${var.chef_clientv} of chef-client installed'",
      "sudo chef-solo -j /tmp/dna.json -N ${format("%s-%03d.%s", var.be_hostname, count.index + 2, var.domain)} -o 'recipe[system::default]'",
      "sudo rm -f /tmp/dna.json",
      "curl -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-server -d /tmp -v ${var.chef_serverv}",
      "sudo chef-server-ctl reconfigure",
      "sudo chef-server-ctl install chef-manage",
      "sudo chef-manage-ctl reconfigure",
    ]
  }
}
resource "aws_route53_record" "chef-frontends-private" {
  count   = "${length(keys(var.aws_subnets)) - 1}"
  zone_id = "${lookup(var.aws_route53, "internal")}"
  name    = "${element(aws_instance.chef-frontends.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.route53_ttl}"
  records = ["${element(aws_instance.chef-frontends.*.private_ip, count.index)}"]
}
resource "aws_route53_record" "chef-frontends-public" {
  count   = "${length(keys(var.aws_subnets)) - 1}"
  zone_id = "${lookup(var.aws_route53, "external")}"
  name    = "${element(aws_instance.chef-frontends.*.tags.Name, count.index)}"
  type    = "A"
  ttl     = "${var.route53_ttl}"
  records = ["${element(aws_instance.chef-frontends.*.public_ip, count.index)}"]
}
resource "aws_route53_record" "chef-ha-elb" {
  zone_id = "${lookup(var.aws_route53, "external")}"
  name    = "${var.hostname}.${var.domain}"
  type    = "CNAME"
  ttl     = "${var.route53_ttl}"
  records = ["${aws_elb.chef-ha-frontend.dns_name}"]
}
# knife.rb templating
resource "template_file" "knife-rb" {
  template = "${file("${path.module}/files/knife-rb.tpl")}"
  vars {
    user   = "${var.chef_usrn}"
    fqdn   = "${var.hostname}.${var.domain}"
    org    = "${var.chef_orgs}"
  }
}
# Setting up Chef Server
resource "null_resource" "chef-setup" {
  connection {
    host        = "${aws_instance.chef-frontend.public_ip}"
    user        = "${lookup(var.ami_usermap, var.ami_os)}"
    private_key = "${var.aws_private_key_file}"
  }
  # TODO: Maybe create parametertized script to run these commands (wrapping chef-server-ctl)
  provisioner "remote-exec" {
    inline = [
      "sudo chef-server-ctl user-create ${var.chef_usrn} ${var.chef_usrf} ${var.chef_usrl} ${var.chef_usre} ${base64sha256(aws_instance.chef-frontend.id)} -f /tmp/${var.chef_usrn}.pem",
      "sudo chef-server-ctl org-create ${var.chef_orgs} '${var.chef_orgl}' --association_user ${var.chef_usrn} --filename /tmp/${var.chef_orgs}-validator.pem",
      "sudo chown ${lookup(var.ami_usermap, var.ami_os)} /tmp/${var.chef_usrn}.pem /tmp/${var.chef_orgs}-validator.pem",
    ]
  }
  # Copy back files
  provisioner "local-exec" {
    command = <<-EOC
      rm -f .chef/${var.chef_orgs}-validator.pem .chef/${var.chef_usrn}.pem
      scp -r -o stricthostkeychecking=no -i ${var.aws_private_key_file} ${lookup(var.ami_usermap, var.ami_os)}@${aws_instance.chef-frontend.public_ip}:/tmp/${var.chef_orgs}-validator.pem .chef/${var.chef_orgs}-validator.pem
      scp -r -o stricthostkeychecking=no -i ${var.aws_private_key_file} ${lookup(var.ami_usermap, var.ami_os)}@${aws_instance.chef-frontend.public_ip}:/tmp/${var.chef_usrn}.pem .chef/${var.chef_usrn}.pem
      EOC
  }
}
resource "null_resource" "knife-rb" {
  # Generate knife.rb
  provisioner "local-exec" {
    command = <<-EOC
      rm -f .chef/knife.rb
      cat > .chef/knife.rb <<EOF
      ${template_file.knife-rb.rendered}
      EOF
      EOC
  }
}
# Generate pretty output format
resource "template_file" "chef-creds" {
  depends_on = ["null_resource.chef-setup"]
  template = "${file("${path.module}/files/chef-server-creds.tpl")}"
  vars {
    user   = "${var.chef_usrn}"
    pass   = "${base64sha256(aws_instance.chef-frontend.id)}"
    user_p = ".chef/${var.chef_usrn}.pem"
    fqdn   = "${var.hostname}.${var.domain}"
    org    = "${var.chef_orgs}"
    pem    = ".chef/${var.chef_orgs}-validator.pem"
  }
}
