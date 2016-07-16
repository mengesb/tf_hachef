# tf_hachef

This terraform plan makes use of chef-backend and chef-server-core to create a
Chef HA architecture spread across multiple AWS availability zones within one
AWS region. Cross region deployment is not supported with this plan or with
chef-backend at this time.

By default, this terraform plan will create a VPC, subnets, security groups,
security group rules, frontend nodes (chef-server-core), backend nodes
(chef-backend), and an AWS ELB comprised of the frontend nodes. Minimum pre-run
setup required is uploading a SSL certificate and SSH key to AWS, as well as
having a DNS zone defined in AWS's Route53 service (two zones, internal and
external).

This plan will deploy one (1) frontend and backend node to each AWS availability
zone indicated in the map variable `aws_subnets`. Minimum required nodes for
chef-backend is three (3), so please configure at least 3 subnets in different
availability zones.

## Assumptions

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
    * 22/tcp: SSH from anywhere (default), restrict with `${allowed_cidrs}`
* Creates subnets spread across AWS AZs, minimum three (3) required
* Understand Terraform and ability to read the source


## Usage


### Module

Due to the extensive use of maps this isn't module compatible at this time.
Terraform has planned better support for maps passed to modules in version
0.7.0 but at the time of writing it is not available.


### Directly

1. Clone this repo: `git clone https://github.com/mengesb/tf_hachef.git`
2. Make a local terraform.tfvars file: `cp terraform.tfvars.example terraform.tfvars`
3. Edit `terraform.tfvars` with your editor of choice, ensuring `accept_license` is set to `true`
4. Get dependencies: `terraform get`
5. Test the plan: `terraform plan`
6. Apply the plan: `terraform apply`


## Supported OSes

All supported OSes are 64-bit and HVM (though PV should be supported)

* Ubuntu 12.04 LTS
* Ubuntu 14.04 LTS (default)
* Ubuntu 16.04 LTS (pending)
* CentOS 6
* CentOS 7 (pending)
* Others (here be dragons! Please see Map Variables)


## AWS

These resources will incur charges on your AWS bill. It is your responsibility to delete the resources.


## Input variables


### AWS variables (including AWS maps)

* `aws_settings`: AWS provisioner settings map
  * `access_key`: Your AWS key, usually referred to as `AWS_ACCESS_KEY_ID`
  * `secret_key`: Your secret for your AWS key, usually referred to as `AWS_SECRET_ACCESS_KEY`
  * `region`: AWS region you want to deploy to. Default: `us-east-1`
* `aws_vpc`: AWS VPC settings map
  * `cidr_block`: CIDR block for VPC creation. Default: `10.20.30.0/24`
  * `instance_tenancy`: AWS instance tenancy. Default: `default`
  * `enable_dns_support`: Support DNS in VPC (required). Default: `true`
  * `enable_dns_hostnames`: Support DNS hostnames (required). Default: `true`
  * `tags_name`: AWS Name tag for VPC. Default: `Chef HA VPC`
* `aws_subnets`: AWS map to create subnets in VPC
  * `KEY`: You create the key labeled as the availability zone (i.e us-east-1a)
  * Default keys: `us-east-1a`, `us-east-1c`, `us-east-1d`, `us-east-1e`
  * `VALUE`: Value is the CIDR subnet to create in that availability zone
  * Default values: `10.20.30.0/26`, `10.20.30.64/26`, `10.20.30.128/26`, `10.20.30.192/26`
* `aws_subnet_map`: Subnet map defaulting the public IP assignment in that availability zone's subnet
  * `KEY`: Must have the same keys as `aws_subnets`. Default: reference `aws_subnets`
  * `VALUE`: Can be `true` or `false`. Default: `true`
* `aws_route53`: Map for internal and external Route53 zone IDs
  * `internal`: Route53 internal zone ID
  * `external`: Route53 external zone ID
* `aws_elb_certificate`: AWS identifier for uploaded SSL certificate to use with AWS ELB
* `aws_flavor`: The AWS instance type. Default: `c3.xlarge`
* `aws_key_name`: The private key pair name on AWS to use (String)
* `aws_private_key_file`: The full path to the private kye matching `aws_key_name` public key on AWS


### tf_hachef specific variables

* `accept_license`: [Chef MLSA license](https://www.chef.io/online-master-agreement/) agreement. Default: `false`; change to `true` to indicate agreement
* `allowed_cidrs`: The comma seperated list of addresses in CIDR format to allow SSH access. Default: `0.0.0.0/0`
* `be_hostname`: Base hostname to generate backend hostnames. Default: `localhostbe`
* `chef_clientv`: Chef client version. Default: `12.12.15`
* `chef_serverv`: Chef Server version to install. Default `12.8.0`
* `chef_orgl`: Chef organization long name. Default: `Chef Organization`
* `chef_orgs`: Chef organization to create. Default: `chef`
* `chef_usre`: Chef Server user's e-mail address. Default: `chef@domain.tld`
* `chef_usrf`: Chef Server user's first name. Default: `Chef`
* `chef_usrl`: Chef Server user's last name. Default: `User`
* `chef_usrn`: First Chef Server user. Default: `chef`
* `domain`: Server's basename. Default: `localhost`
* `fe_hostname`: Base hostname to generate frontend hostnames. Default: `localhostfe`
* `hostname`: Chef server's API hostname. Default: `localhost`
* `log_to_file`: Log chef-client to file. Default: `true`
* `public_ip`: Associate public IP to instance. Default `true`
* `root_delete_termination`: Delete root device on VM termination. Default: `true`
* `root_volume_size`: Size of the root volume in GB. Default: `20`
* `root_volume_type`: Type of root volume. Supports `gp2` and `standard`. Default: `standard`
* `route53_ttl`: Default Route53 record TTL. Default: `180`
* `ssl_cert`: SSL certificate in PEM format
* `ssl_key`: SSL certificate key
* `tag_description`: AWS instance Name tag. Default `Created using Terraform`


### Map variables

The below mapping variables construct selection criteria

* `ami_map`: AMI selection map comprised of `ami_os` and `aws_region`
* `ami_usermap`: Default username selection map based off `ami_os`

The `ami_map` is a combination of `ami_os` and `aws_region` which declares the
AMI selected. To override this pre-declared AMI, define

```
ami_map.<ami_os>-<aws_region> = "value"
```

Variable `ami_os` should be one of the following:

* centos6
* centos7
* ubuntu12
* ubuntu14 (default)
* ubuntu16

Variable `aws_region` should be one of the following:

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

Map `ami_usermap` uses `ami_os` to look the default username for interracting
with the instance. To override this pre-declared user, define

```
ami_usermap.<ami_os> = "value"
```


## Outputs

* `credentials`: Formatted text output with details about the Chef Server


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

