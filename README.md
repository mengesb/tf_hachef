# tf_hachef

This terraform plan makes use of chef-backend and chef-server-core to create a
Chef HA architecture spread across multiple AWS availability zones within one
AWS region. Cross region deployment is not supported with this plan or with
chef-backend at this time.

By default, this terraform plan will create a VPC, subnets, security groups,
security group rules, frontend nodes (chef-server-core), backend nodes
(chef-backend), and an AWS ELB comprised of the frontend nodes.

This plan is rather large and complex. Be sure to read through the
[README](README.md) in full.

## Assumptions

This terraform plan is designed for near-production use. Please take note as
the requirements are extensive

* Requires:
  * AWS (duh!)
  * Route53 internal and external zones
  * Uploaded to AWS a SSL certificate (wildcard preferred)
  * SSL certificate/key for created instance (local files to upload to instances)
  * Terraform >= 0.6.14
* Uses public IPs and public DNS
* Creates default security group as follows:
  * Frontend:
    * 443/tcp: HTTPS from anywhere
    * 80/tcp: HTTP from anywhere
  * Backend:
    * ALL: inside security group
    * 2379/tcp: etcd from Frontend SG
    * 5432/tcp: PostgreSQL from Frontend SG
    * 7331/tcp: leaderl from Frontend SG
    * 9200/tcp: Elasticsearch from Frontend SG
  * SSH Security Group:
    * 22/tcp: SSH from anywhere (default), restrict with `${ssh_cidrs}` list
* Creates subnets spread across AWS AZs
* Minimum three (3) chef-backend instances required (`chef["backend_count"]`)
* Minimum two (2) chef-server-core instances required (`chef["frontend_count"]`)
* Understand Terraform and ability to read the source


## Usage


### Module

Usage as a module has not been tested, however in Terraform 0.7.0 many things
are first-class which were not before. Choose to run this way at your own risk


### Directly

1. Clone this repo: `git clone https://github.com/mengesb/tf_hachef.git`
2. Make a local terraform.tfvars file: `cp terraform.tfvars.example terraform.tfvars`
3. Edit `terraform.tfvars` with your editor of choice, ensuring
`var.chef["accept_mlsa"]` is set to `true`
4. Test the plan: `terraform plan`
5. Apply the plan: `terraform apply`


## Supported OSes

All supported OSes are 64-bit and HVM (though PV should be supported)

* Ubuntu 12.04 LTS
* Ubuntu 14.04 LTS (default)
* Ubuntu 16.04 LTS (pending)
* CentOS 6
* CentOS 7 (pending)
* Others (here be dragons! Please see Map Variables)


## AWS

These resources will incur charges on your AWS bill. It is your responsibility
to delete the resources.


## Input variables


* `provider`: AWS provider settings
  * `access_key`: Your AWS key, usually referred to as `AWS_ACCESS_KEY_ID`
  * `region`: AWS region you want to deploy to. Default: `us-east-1`
  * `secret_key`: Your secret for your AWS key, usually referred to as `AWS_SECRET_ACCESS_KEY`
* `vpc`: AWS VPC settings
  * `cidr`: CIDR block for VPC creation. Default: `10.20.30.0/24`
  * `dns_hostnames`: Support DNS hostnames (required). Default: `true`
  * `dns_support`: Support DNS in VPC (required). Default: `true`
  * `tags_desc`: AWS Name tag for VPC. Default: `Chef HA VPC`
  * `tenancy`: AWS instance tenancy. Default: `default`
* `subnets`: AWS subnet settings
  * This map is a dynamic map. Please read below:
  * `KEY`: You create the key labeled as the availability zone (i.e us-east-1a)
  * Default keys: `us-east-1a`, `us-east-1c`, `us-east-1d`, `us-east-1e`
  * `VALUE`: Value is the CIDR subnet to create in that availability zone
  * Default values: `10.20.30.0/26`, `10.20.30.64/26`, `10.20.30.128/26`, `10.20.30.192/26`
* `subnets_public`: Subnet map defaulting the public IP assignment in that availability zone's subnet
  * `KEY`: Must have the same keys as `subnets`. Default: reference `subnets`
  * `VALUE`: Can be `true` or `false`. Default: `true`
* `ssh_cidrs`: List of CIDR ranges allowed SSH access. Default: `["0.0.0.0/0"]`
* `ami`: AMI map for selecting the AMI
  * The `KEY` is comprised of the `os`-`instance["(frontend|backend)_type"]`-`provider["region"]`
  * The `value` is a mapping based on AMIs found publicly available as of 2016-03-14
* `os`: The operating system for the deployed instance. Default: `ubuntu14`
* `ami_user`: Mapping of `os` to a default user for the instance. Default: `ubuntu14 = "ubuntu"`
* `ssl_certificate`: SSL Certificate information for chef-server-core installation
  * `cert_file`: Full path to certificate file (usually `.crt` or `.pem` file)
  * `key_file`: Full path to the certificate key file (usually `.key` file)
* `elb`: AWS ELB settings
  * `certificate`: The uploaded identifier for the SSL certificate to use with AWS ELB
  * `hostname`: Basename for the hostname. Default: `chefelb`
  * `tags_desc`: Default tag for ELB. Default: `Created using Terraform`
* `chef_backend`: Chef backend settings
  * `count`: Count of chef-backend instances to deploy. Default: `4`
  * `version`: Chef backend version to install. Default: `1.0.9`
* `chef_client`: Chef client version to install. Default: `12.12.15`
* `chef_mlsa`: Indicate acceptance of the Chef MLSA. Must update to `true`. Default: `false`
* `chef_org`: Chef organization settings
  * `short`: Chef organization to create. Default: `chef`
  * `long`: Chef long organization name. Default: `Chef Organization`
* `chef_server`: Chef server core settings
  * `count`: Chef server core instance count. Default: `4`
  * `version`: Chef server core version to install. Default: `12.8.0`
* `chef_user`: Chef initial user settings
  * `username`: Chef username to create. Default: `chef`
  * `email`: Chef user e-mail address. Default: `chef@domain.tld`
  * `first_name`: Chef user first name. Default: `Chef`
  * `last_name`: Chef user last name. Default: `User`
* `instance`: Map of various AWS instance settings (backend and frontend)
  * `backend_flavor`: Backend default instance type. Default: `r3.xlarge`
  * `backend_iops`: Backend root volume IOPs (when using `io1`). Default: `6000`
  * `backend_public`: Backend default association to public ip. Default: `true`
  * `backend_size`: Backend root volume size in gigabytes. Default: `200`
  * `backend_term`: Delete root volume on VM termination. Default: `true`
  * `backend_type`: Backend root volume type: Default `io1`
  * `ebs_optimized`: Deploy EBS optimized root volume. Default `true`
  * `frontend_flavor`: Frontend default instance type. Default: `r3.xlarge`
  * `frontend_iops`: Frontend root volume IOPs (when using `io1`). Default: `6000`
  * `frontend_public`: Frontend default association to public ip. Default: `true`
  * `frontend_size`: Frontend root volume size in gigabytes. Default: `200`
  * `frontend_term`: Delete root volume on VM termination. Default: `true`
  * `frontend_type`: Frontend root volume type: Default `io1`
  * `tags_desc` = "Created using Terraform"
* `instance_hostname`: Map of frontend and backend base hostnames
  * `backend`: Chef backend base hostname. Default: `chefbe`
  * `frontend`: Chef server core base hostname. Default: `chefbe`
* `instance_keys`: Map of SSH key settings to deploy and access AWS instances
  * `key_name`: The private key pair name on AWS to use (String)
  * `key_file`: The full path to the private kye matching `instance_keys["key_name"]` public key on AWS
* `domain`: Domain name for instances and ELB. Default: `localdomain`
* `r53_zones`: AWS Route53 zone settings
  * `internal`: Route53 internal zone ID
  * `external`: Route53 external zone ID
* `r53_ttls`: AWS Route53 TTL default settings
  * `internal`: Time to live setting for internal zone route53 records. Default: `180`
  * `external`: Time to live setting for external zone route53 records. Default: `180`


### AMI map and customizing

The below mapping variables construct selection criteria

* `ami`: AMI selection map comprised of `os`, `instance["(frontend|backend)_type"]` and `aws_region`
* `ami_user`: Default username selection map based off `ami_os`

To override this, construct the maps in the following manner:

```
ami = {
  myos-io1-us-west-1 = "ami-________"
}
os = "myos"
ami_user = {
  myos = "myloginuser"
}

instance = {
  ...
  backend_type = "io1"
  ...
}
```

Defaults for `os` map:

* centos6
* centos7
* ubuntu12
* ubuntu14 (default)
* ubuntu16

Default region in `provider["region"]` should likely be one of the following:

* us-east-1 (default)
* us-west-2
* us-west-1
* eu-central-1
* eu-west-1
* ap-southeast-1
* ap-southeast-2
* ap-northeast-1
* ap-northeast-2
* sa-east-1
* Custom (must be an AWS region, requires setting `ami_map` and setting AMI value)


## Outputs

* `chef_manage_url`: URL of the chef server's management interface
* `chef_username`: Username for the chef user created
* `chef_user_password`: Password for the chef user created
* `knife_rb`: Path to the knife.rb file


## Contributors

* [Brian Menges](https://github.com/mengesb)


## Runtime sample

You can view a runtime output sample here: [tf_hachef_runtime.txt](https://gist.github.com/mengesb/0771c38a64d3dd7aa609dc31f5933bba)


## Contributing

Please understand that this is a work in progress and is subject to change
rapidly. Be sure to keep up to date with the repo should you fork, and feel
free to contact me regarding development and suggested direction. Familiarize
yoursef with the [contributing](CONTRIBUTING.md) before making/submitting changes.


## CHANGELOG

Please refer to the [`CHANGELOG.md`](CHANGELOG.md)


## License

This is licensed under [the Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0).

