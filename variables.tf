#
# AWS provider specific configs
#
variable "aws_settings" {
  description = "Map of AWS settings"
  default     = {
    access_key = ""
    secret_key = ""
    region     = "us-east-1"
  }
}
#
# AWS VPC settings
#
variable "aws_vpc" {
  description = "Map of AWS VPC settings"
  default     = {
    cidr_block           = "10.20.30.0/24"
    instance_tenancy     = "default"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags_name            = "Chef HA VPC"
  }
}
#
# AWS Subnet settings
#
variable "aws_subnets" {
  description = "Map of AWS availability zones (key) to subnet CIDR (value) assignments"
  default     = {
    us-east-1a = "10.20.30.0/26"
    us-east-1c = "10.20.30.64/26"
    us-east-1d = "10.20.30.128/26"
    us-east-1e = "10.20.30.192/26"
  }
}
variable "aws_subnet_map" {
  description = "Map of AWS availability zones (key) to boolean map_public_ip_on_launch (value) assignments"
  default = {
    us-east-1a = true
    us-east-1c = true
    us-east-1d = true
    us-east-1e = true
  }
}
#
# AWS Route53 Settings
#
variable "aws_route53" {
  description = "Map of AWS Route53 Zone IDs"
  default     = {
    external  = ""
    internal  = ""
  }
}
variable "aws_elb_certificate" {
  description = "Identifier for uploaded SSL certificate used with AWS ELB"
}
variable "aws_flavor" {
  description = "AWS Instance type to deploy"
  default     = "c3.xlarge"
}
variable "aws_key_name" {
  description = "Name of the key pair uploaded to AWS"
}
variable "aws_private_key_file" {
  description = "Full path to your local private key"
}
#
# AMI mapping
#
variable "ami_map" {
  description = "AMI map of OS/region (2016-03-14)"
  default     = {
    centos7-us-east-1       = "ami-6d1c2007"
    centos7-us-west-2       = "ami-d2c924b2"
    centos7-us-west-1       = "ami-af4333cf"
    centos7-eu-central-1    = "ami-9bf712f4"
    centos7-eu-west-1       = "ami-7abd0209"
    centos7-ap-southeast-1  = "ami-f068a193"
    centos7-ap-southeast-2  = "ami-fedafc9d"
    centos7-ap-northeast-1  = "ami-eec1c380"
    centos7-ap-northeast-2  = "ami-c74789a9"
    centos7-sa-east-1       = "ami-26b93b4a"
    centos6-us-east-1       = "ami-1c221e76"
    centos6-us-west-2       = "ami-05cf2265"
    centos6-us-west-1       = "ami-ac5f2fcc"
    centos6-eu-central-1    = "ami-2bf11444"
    centos6-eu-west-1       = "ami-edb9069e"
    centos6-ap-southeast-1  = "ami-106aa373"
    centos6-ap-southeast-2  = "ami-87d2f4e4"
    centos6-ap-northeast-1  = "ami-fa3d3f94"
    centos6-ap-northeast-2  = "ami-56478938"
    centos6-sa-east-1       = "ami-03b93b6f"
    ubuntu16-us-east-1      = "-1"
    ubuntu16-us-west-2      = "-1"
    ubuntu16-us-west-1      = "-1"
    ubuntu16-eu-central-1   = "-1"
    ubuntu16-eu-west-1      = "-1"
    ubuntu16-ap-southeast-1 = "-1"
    ubuntu16-ap-southeast-2 = "-1"
    ubuntu16-ap-northeast-1 = "-1"
    ubuntu16-ap-northeast-2 = "-1"
    ubuntu16-sa-east-1      = "-1"
    ubuntu14-us-east-1      = "ami-415f6d2b"
    ubuntu14-us-west-2      = "ami-3d2cce5d"
    ubuntu14-us-west-1      = "ami-1d25557d"
    ubuntu14-eu-central-1   = "ami-9b9c86f7"
    ubuntu14-eu-west-1      = "ami-abc579d8"
    ubuntu14-ap-southeast-1 = "ami-f500c996"
    ubuntu14-ap-southeast-2 = "ami-1f30167c"
    ubuntu14-ap-northeast-1 = "ami-88686be6"
    ubuntu14-ap-northeast-2 = "-1"
    ubuntu14-sa-east-1      = "ami-f3e4669f"
    ubuntu12-us-east-1      = "ami-88dfdee2"
    ubuntu12-us-west-2      = "ami-1a977e7a"
    ubuntu12-us-west-1      = "ami-4f285a2f"
    ubuntu12-eu-central-1   = "ami-3cf61153"
    ubuntu12-eu-west-1      = "ami-65932916"
    ubuntu12-ap-southeast-1 = "ami-26e32845"
    ubuntu12-ap-southeast-2 = "ami-d54e6eb6"
    ubuntu12-ap-northeast-1 = "ami-f2afa79c"
    ubuntu12-ap-northeast-2 = "-1"
    ubuntu12-sa-east-1      = "ami-2661ec4a"
  }
}
variable "ami_os" {
  description = "Chef server OS (options: centos7, centos6, ubuntu16, [ubuntu14])"
  default     = "ubuntu14"
}
variable "ami_usermap" {
  description = "Default username map for AMI selected"
  default     = {
    centos7   = "centos"
    centos6   = "centos"
    ubuntu16  = "ubuntu"
    ubuntu14  = "ubuntu"
    ubuntu12  = "ubuntu"
  }
}
#
# specific configs
#
variable "accept_license" {
  description = "Acceptance of the Chef MLSA: https://www.chef.io/online-master-agreement/"
  default     = false
}
variable "allowed_cidrs" {
  description = "List of CIDRs to allow SSH from (CSV list allowed)"
  default     = "0.0.0.0/0"
}
variable "be_hostname" {
  description = "Chef backend hostname"
  default     = "localhostbe"
}
#
variable "chef_clientv" {
  description = "Version of chef-client to install"
  default     = "12.12.15"
}
variable "chef_serverv" {
  description = "Version of chef-server-core to install"
  default     = "12.8.0"
}
variable "chef_orgl" {
  description = "Chef server organization name (long form)"
  default     = "Chef Organization"
}
variable "chef_orgs" {
  description = "Chef server organization name (short form)"
  default     = "chef"
}
variable "chef_usre" {
  description = "Chef user's e-mail"
  default     = "chef@domain.tld"
}
variable "chef_usrf" {
  description = "Chef user's first name"
  default     = "Chef"
}
variable "chef_usrl" {
  description = "Chef user's last name"
  default     = "User"
}
variable "chef_usrn" {
  description = "Chef server username"
  default     = "chef"
}
variable "domain" {
  description = "Chef server domain name"
  default     = "localdomain"
}
variable "fe_hostname" {
  description = "Chef frontend hostname"
  default     = "localhostfe"
}
variable "hostname" {
  description = "Chef server hostname"
  default     = "localhost"
}
variable "log_to_file" {
  description = "Output chef-client runtime to logfiles/"
  default     = true
}
variable "public_ip" {
  description = "Associate a public IP to the instance"
  default     = true
}
variable "root_delete_termination" {
  description = "Delete server root block device on termination"
  default     = true
}
variable "root_volume_size" {
  description = "Size in GB of root device"
  default     = 20
}
variable "root_volume_type" {
  description = "Type of root volume"
  default     = "standard"
}
variable "route53_ttl" {
  description = "Default TTL for Route53 records (180)"
  default     = 180
}
variable "ssl_cert" {
  description = "SSL Certificate in PEM format"
}
variable "ssl_key" {
  description = "Key for SSL Certificate"
}
variable "tag_description" {
  description = "Chef server AWS description tag text"
  default     = "Created using Terraform"
}
