#
# AWS provider specific configs
#
variable "provider" {
  description       = "Map of AWS provider settings"
  default           = {
    access_key      = ""
    region          = "us-east-1"
    secret_key      = ""
  }
}
#
# AWS VPC settings
#
variable "vpc" {
  type              = "map"
  description       = "Map of AWS VPC settings"
  default           = {
    cidr            = "10.20.30.0/24"
    dns_hostnames   = true
    dns_support     = true
    tags_desc       = "Chef HA VPC"
    tenancy         = "default"
  }
}
#
# AWS gateway settings
#
variable "gateway" {
  type              = "string"
  default           = "Chef HA GW"
}
#
# AWS subnet settings
#
variable "subnets" {
  type              = "map"
  description       = "Map of AWS availability zones (key) to subnet CIDR (value) assignments"
  default           = {
    us-east-1a      = "10.20.30.0/26"
    us-east-1c      = "10.20.30.64/26"
    us-east-1d      = "10.20.30.128/26"
  }
}
variable "subnets_public" {
  type              = "map"
  description       = "Map of AWS availability zones (key) to boolean map_public_ip_on_launch (value) assignments"
  default           = {
    us-east-1c      = true
    us-east-1a      = true
    us-east-1d      = true
  }
}
#
# AWS security group settings
# CIDRs to allow SSH connections
variable "ssh_cidrs" {
  type        = "list"
  description = "List of CIDRs to allow SSH from (CSV list allowed)"
  default     = ["0.0.0.0/0"]
}
#
# AWS AMI settings map
#
variable "ami" {
  type              = "map"
  description       = "AMI map of OS/region (2016-03-14)"
  default           = {
    centos6-gp2-us-gov-west-1   = ""
    centos6-gp2-us-east-1       = "ami-1c221e76"
    centos6-gp2-us-west-2       = "ami-05cf2265"
    centos6-gp2-us-west-1       = "ami-ac5f2fcc"
    centos6-gp2-eu-central-1    = "ami-2bf11444"
    centos6-gp2-eu-west-1       = "ami-edb9069e"
    centos6-gp2-cn-north-1      = ""
    centos6-gp2-ap-south-1      = "ami-9b1c76f4"
    centos6-gp2-ap-southeast-1  = "ami-106aa373"
    centos6-gp2-ap-southeast-2  = "ami-87d2f4e4"
    centos6-gp2-ap-northeast-1  = "ami-fa3d3f94"
    centos6-gp2-ap-northeast-2  = "ami-56478938"
    centos6-gp2-sa-east-1       = "ami-03b93b6f"

    centos7-gp2-us-gov-west-1   = ""
    centos7-gp2-us-east-1       = "ami-6d1c2007"
    centos7-gp2-us-west-2       = "ami-d2c924b2"
    centos7-gp2-us-west-1       = "ami-af4333cf"
    centos7-gp2-eu-central-1    = "ami-9bf712f4"
    centos7-gp2-eu-west-1       = "ami-7abd0209"
    centos7-gp2-cn-north-1      = ""
    centos7-gp2-ap-south-1      = "ami-95cda6fa"
    centos7-gp2-ap-southeast-1  = "ami-f068a193"
    centos7-gp2-ap-southeast-2  = "ami-fedafc9d"
    centos7-gp2-ap-northeast-1  = "ami-eec1c380"
    centos7-gp2-ap-northeast-2  = "ami-c74789a9"
    centos7-gp2-sa-east-1       = "ami-26b93b4a"

    rhel7-gp2-us-gov-west-1     = ""
    rhel7-gp2-us-east-1         = "ami-85241def"
    rhel7-gp2-us-west-2         = "ami-a3fa16c3"
    rhel7-gp2-us-west-1         = "ami-f7eb9b97"
    rhel7-gp2-eu-central-1      = "ami-b6688dd9"
    rhel7-gp2-eu-west-1         = "ami-ce66d8bd"
    rhel7-gp2-cn-north-1        = ""
    rhel7-gp2-ap-south-1        = "ami-cdbdd7a2"
    rhel7-gp2-ap-southeast-1    = "ami-dccc04bf"
    rhel7-gp2-ap-southeast-2    = "ami-286e4f4b"
    rhel7-gp2-ap-northeast-1    = "ami-a05854ce"
    rhel7-gp2-ap-northeast-2    = "ami-d35d93bd"
    rhel7-gp2-sa-east-1         = "ami-2b068447"

    rhel6-gp2-us-gov-west-1     = ""
    rhel6-gp2-us-east-1         = "ami-ef14f582"
    rhel6-gp2-us-west-2         = "ami-6fb7450f"
    rhel6-gp2-us-west-1         = "ami-4b2b522b"
    rhel6-gp2-eu-central-1      = "ami-e017f58f"
    rhel6-gp2-eu-west-1         = "ami-f990188a"
    rhel6-gp2-cn-north-1        = ""
    rhel6-gp2-ap-south-1        = "ami-cbb0daa4"
    rhel6-gp2-ap-southeast-1    = "ami-0903d46a"
    rhel6-gp2-ap-southeast-2    = "ami-73507c10"
    rhel6-gp2-ap-northeast-1    = "ami-beccd6d0"
    rhel6-gp2-ap-northeast-2    = "ami-0d4d8563"
    rhel6-gp2-sa-east-1         = "ami-074ec76b"

    ubuntu14-gp2-us-gov-west-1  = "ami-6770ce06"
    ubuntu14-gp2-us-east-1      = "ami-3bdd502c"
    ubuntu14-gp2-us-west-2      = "ami-d732f0b7"
    ubuntu14-gp2-us-west-1      = "ami-48db9d28"
    ubuntu14-gp2-eu-central-1   = "ami-26c43149"
    ubuntu14-gp2-eu-west-1      = "ami-ed82e39e"
    ubuntu14-gp2-cn-north-1     = "ami-bead78d3"
    ubuntu14-gp2-ap-south-1     = ""
    ubuntu14-gp2-ap-southeast-1 = "ami-21d30f42"
    ubuntu14-gp2-ap-southeast-2 = "ami-ba3e14d9"
    ubuntu14-gp2-ap-northeast-1 = "ami-63b44a02"
    ubuntu14-gp2-ap-northeast-2 = ""
    ubuntu14-gp2-sa-east-1      = "ami-dc48dcb0"

    ubuntu14-io1-us-gov-west-1  = "ami-1770ce76"
    ubuntu14-io1-us-east-1      = "ami-aac24fbd"
    ubuntu14-io1-us-west-2      = "ami-b828ead8"
    ubuntu14-io1-us-west-1      = "ami-03dd9b63"
    ubuntu14-io1-eu-central-1   = "ami-d0c431bf"
    ubuntu14-io1-eu-west-1      = "ami-81bcddf2"
    ubuntu14-io1-cn-north-1     = "ami-bfad78d2"
    ubuntu14-io1-ap-south-1     = ""
    ubuntu14-io1-ap-southeast-1 = "ami-9fd30ffc"
    ubuntu14-io1-ap-southeast-2 = "ami-66391305"
    ubuntu14-io1-ap-northeast-1 = "ami-b7b947d6"
    ubuntu14-io1-ap-northeast-2 = ""
    ubuntu14-io1-sa-east-1      = "ami-bb49ddd7"

    ubuntu12-gp2-us-gov-west-1  = "ami-1daf117c"
    ubuntu12-gp2-us-east-1      = "ami-b74688da"
    ubuntu12-gp2-us-west-2      = "ami-312ee851"
    ubuntu12-gp2-us-west-1      = "ami-951651f5"
    ubuntu12-gp2-eu-central-1   = "ami-13db307c"
    ubuntu12-gp2-eu-west-1      = "ami-0fe57f7c"
    ubuntu12-gp2-cn-north-1     = "ami-109d487d"
    ubuntu12-gp2-ap-south-1     = "ami-4c9cf623"
    ubuntu12-gp2-ap-southeast-1 = "ami-ba22f0d9"
    ubuntu12-gp2-ap-southeast-2 = "ami-c29db5a1"
    ubuntu12-gp2-ap-northeast-1 = "ami-1505f474"
    ubuntu12-gp2-ap-northeast-2 = ""
    ubuntu12-gp2-sa-east-1      = "ami-36a83d5a"

    ubuntu12-io1-us-gov-west-1  = "ami-43af1122"
    ubuntu12-io1-us-east-1      = "ami-e9468884"
    ubuntu12-io1-us-west-2      = "ami-6028ee00"
    ubuntu12-io1-us-west-1      = "ami-30084f50"
    ubuntu12-io1-eu-central-1   = "ami-a1c42fce"
    ubuntu12-io1-eu-west-1      = "ami-23e47e50"
    ubuntu12-io1-cn-north-1     = "ami-ec75bf81"
    ubuntu12-io1-ap-south-1     = "ami-c79df7a8"
    ubuntu12-io1-ap-southeast-1 = "ami-2720f244"
    ubuntu12-io1-ap-southeast-2 = "ami-c59db5a6"
    ubuntu12-io1-ap-northeast-1 = "ami-1002f371"
    ubuntu12-io1-ap-northeast-2 = ""
    ubuntu12-io1-sa-east-1      = "ami-afab3ec3"
  }
}
variable "os" {
  type               = "string"
  description        = "Chef server OS (options: centos7, centos6, ubuntu16, [ubuntu14])"
  default            = "ubuntu14"
}
variable "ami_user" {
  type               = "map"
  description        = "Default username map for AMI selected"
  default            = {
    centos7          = "centos"
    centos6          = "centos"
    ubuntu16         = "ubuntu"
    ubuntu14         = "ubuntu"
    ubuntu12         = "ubuntu"
  }
}
#
# SSL settings
#
variable "ssl_certificate" {
  type               = "map"
  description        = "SSL Certificate information"
  default            = {
    cert_file        = ""
    key_file         = ""
  }
}
#
# AWS ELB settings
#
variable "elb" {
  type              = "map"
  description       = ""
  default           = {
    certificate     = ""
    hostname        = "elb"
    tags_desc       = "Created using Terraform"
  }
}
#
# Chef settings
#
variable "chef_backend" {
  type               = "map"
  description        = "Chef backend settings"
  default            = {
    count            = 4
    version          = "1.1.2"
  }
}
variable "chef_server" {
  type               = "map"
  description        = "Chef server core settings"
  default            = {
    count            = 4
    version          = "12.8.0"
  }
}
variable "chef_user" {
  type               = "map"
  description        = "Chef user creation settings"
  default            = {
    email            = "chef@domain.tld"
    first_name       = "Chef"
    last_name        = "User"
    username         = "chef"
  }
}
variable "chef_org" {
  type               = "map"
  description        = "Chef organization settings"
  default            = {
    short            = "chef"
    long             = "Chef Organization"
  }
}
variable "chef_client" {
  type               = "string"
  description        = "Chef client version"
  default            = "12.12.15"
}
variable "chef_mlsa" {
#  type               = "string"
  description        = "Chef MLSA license agreement"
  default            = false
}
#
# AWS EC2 instance settings
#
variable "instance" {
  type              = "map"
  description       = ""
  default           = {
    backend_flavor  = "r3.xlarge"
    backend_iops    = 6000
    backend_public  = true
    backend_size    = 200
    backend_term    = true
    backend_type    = "io1"
    ebs_optimized   = true
    frontend_flavor = "m4.large"
    frontend_iops   = 0
    frontend_public = true
    frontend_size   = 40
    frontend_term   = true
    frontend_type   = "gp2"
    tags_desc       = "Created using Terraform"
  }
}
variable "instance_hostname" {
  type              = "map"
  description       = ""
  default           = {
    backend         = "chefbe"
    frontend        = "cheffe"
  }
}
variable "instance_keys" {
  type              = "map"
  description       = ""
  default           = {
    key_name        = ""
    key_file        = ""
  }
}
variable "domain" {
  description        = "Chef server domain name"
  default            = "localdomain"
}
#
# AWS Route53 settings
#
variable "r53_zones" {
  type              = "map"
  description       = ""
  default           = {
    external        = ""
    internal        = ""
  }
}
variable "r53_ttls" {
  type              = "map"
  description       = ""
  default           = {
    external        = "180"
    internal        = "180"
  }
}

