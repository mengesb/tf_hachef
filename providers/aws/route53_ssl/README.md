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
  * Terraform >= 0.7.3
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


## Recommendations

The defaults set forth in the [variables.tf](variables.tf) file have been set
for good reasons. Please note that a good amount of testing went into defining
these defaults and necessary inputs are defined, for your convenience in
[terraform.tfvars.example](terraform.tfvars.example)


## Input variables


<table>
  <tr>
    <th>Variable</th>
    <th>Key</th>
    <th>Description</th>
    <th>Type</th>
    <th>Default Value</th>
  </tr>
  <tr>
    <td>provider</td>
    <td></td>
    <td>AWS provider map</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>access_key</td>
    <td>AWS access key</td>
    <td>string</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>region</td>
    <td>AWS region for deployment</td>
    <td>string</td>
    <td>us-east-1</td>
  </tr>
  <tr>
    <td></td>
    <td>secret_key</td>
    <td>AWS secret</td>
    <td>string</td>
    <td></td>
  </tr>
  <tr>
    <td>vpc</td>
    <td></td>
    <td>AWS VPC settings map</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>cidr</td>
    <td>CIDR block for VPC</td>
    <td>string</td>
    <td>10.20.30.0/24</td>
  </tr>
  <tr>
    <td></td>
    <td>dns_hostnames</td>
    <td>Support DNS hostnames (required)</td>
    <td>boolean</td>
    <td>true</td>
  </tr>
  <tr>
    <td></td>
    <td>dns_support</td>
    <td>Support DNS in VPC (required)</td>
    <td>boolean</td>
    <td>true</td>
  </tr>
  <tr>
    <td></td>
    <td>tags_desc</td>
    <td>Description tag</td>
    <td>string</td>
    <td>Chef HA VPC</td>
  </tr>
  <tr>
    <td></td>
    <td>tenancy</td>
    <td>AWS instance tenancy</td>
    <td>string</td>
    <td>default</td>
  </tr>
  <tr>
    <td>subnets</td>
    <td></td>
    <td>AWS subnet settings</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>`key`</td>
    <td>AWS AZ to create subnet</td>
    <td>string</td>
    <td>us-east-1a<br>us-east-1c<br>us-east-1d<br>us-east-1e</td>
  </tr>
  <tr>
    <td></td>
    <td>`value`</td>
    <td>Subnet to configure for `key`</td>
    <td>string</td>
    <td>10.20.30.0/26<br>10.20.30.64/26<br>10.20.30.128/26<br>10.20.30.192/26</td>
  </tr>
  <tr>
    <td>ssh_cidrs</td>
    <td></td>
    <td>List of CIDRs allowing SSH</td>
    <td>list</td>
    <td>0.0.0.0/0</td>
  </tr>
  <tr>
    <td>ami</td>
    <td></td>
    <td>AWS AMI map</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>`key`</td>
    <td>Key comprised of of os-type-region</td>
    <td>string</td>
    <td>View [variables.tf](variables.tf)</td>
  </tr>
  <tr>
    <td></td>
    <td>`value`</td>
    <td>AWS AMI identifier</td>
    <td>string</td>
    <td>View [variables.tf](variables.tf)</td>
  </tr>
  <tr>
    <td>os</td>
    <td></td>
    <td>AWS AMI operating system</td>
    <td>string</td>
    <td>ubuntu14</td>
  </tr>
  <tr>
    <td>ami_user</td>
    <td></td>
    <td>Mapping of AMI OS to AMI username</td>
    <td>map</td>
    <td>ubuntu</td>
  </tr>
  <tr>
    <td></td>
    <td>`key`</td>
    <td>AMI OS</td>
    <td>string</td>
    <td>centos7<br>centos6<br>ubuntu16<br>ubuntu14<br>ubuntu12</td>
  </tr>
  <tr>
    <td></td>
    <td>`value`</td>
    <td>Username for `key`</td>
    <td>string</td>
    <td>centos<br>centos<br>ubuntu<br>ubuntu<br>ubuntu</td>
  </tr>
  <tr>
    <td>ssl_certificate</td>
    <td></td>
    <td>SSL certificate information</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>cert_file</td>
    <td>Full path to SSL certificate file</td>
    <td>string</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>key_file</td>
    <td>Full path to SSL certificate key file</td>
    <td>string</td>
    <td></td>
  </tr>
  <tr>
    <td>elb</td>
    <td></td>
    <td>AWS ELB settings</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>certificate</td>
    <td>AWS identifier for SSL certificate</td>
    <td>string</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>hostname</td>
    <td>Base hostname for AWS ELB</td>
    <td>string</td>
    <td>chefelb</td>
  </tr>
  <tr>
    <td></td>
    <td>tags_desc</td>
    <td>Description tag</td>
    <td>string</td>
    <td>Created using Terraform</td>
  </tr>
  <tr>
    <td>chef_backend</td>
    <td></td>
    <td>Chef backend settings</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>count</td>
    <td>Count of chef-backend instances</td>
    <td>integer</td>
    <td>3</td>
  </tr>
  <tr>
    <td></td>
    <td>version</td>
    <td>Version of chef-backend to install</td>
    <td>string</td>
    <td>1.1.2</td>
  </tr>
  <tr>
    <td>chef_client</td>
    <td></td>
    <td>Version of chef-client to install</td>
    <td>string</td>
    <td>12.12.15</td>
  </tr>
  <tr>
    <td>chef_mlsa</td>
    <td></td>
    <td>Chef MLSA licese acceptance</td>
    <td>string</td>
    <td>false</td>
  </tr>
  <tr>
    <td>chef_org</td>
    <td></td>
    <td>Chef server organization settings</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>short</td>
    <td>Chef server organization short name</td>
    <td>string</td>
    <td>chef</td>
  </tr>
  <tr>
    <td></td>
    <td>long</td>
    <td>Chef server organization long name</td>
    <td>Chef Organization</td>
    <td>string</td>
  </tr>
  <tr>
    <td>chef_server</td>
    <td></td>
    <td>Chef server core settings</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>count</td>
    <td>Count of chef-server-core instances</td>
    <td>integer</td>
    <td>2</td>
  </tr>
  <tr>
    <td></td>
    <td>version</td>
    <td>Version of chef-server-core to install</td>
    <td>string</td>
    <td>12.8.0</td>
  </tr>
  <tr>
    <td>chef_user</td>
    <td></td>
    <td>Chef initial user settings</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>email</td>
    <td>Chef user e-mail address</td>
    <td>string</td>
    <td>chef@domain.tld</td>
  </tr>
  <tr>
    <td></td>
    <td>first_name</td>
    <td>Chef user first name</td>
    <td>string</td>
    <td>Chef</td>
  </tr>
  <tr>
    <td></td>
    <td>last_name</td>
    <td>Chef user last name</td>
    <td>string</td>
    <td>User</td>
  </tr>
  <tr>
    <td></td>
    <td>username</td>
    <td>Chef user username</td>
    <td>string</td>
    <td>chef</td>
  </tr>
  <tr>
    <td>instance</td>
    <td></td>
    <td>AWS instance settings</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>backend_flavor</td>
    <td>AWS instance type for chef-backend</td>
    <td>string</td>
    <td>r3.xlarge</td>
  </tr>
  <tr>
    <td></td>
    <td>backend_iops</td>
    <td>Root volume IOPs on chef-backend instance (`io1`)</td>
    <td>integer</td>
    <td>0</td>
  </tr>
  <tr>
    <td></td>
    <td>backend_public</td>
    <td>Associate public IP to chef-backend instance</td>
    <td>boolean</td>
    <td>true</td>
  </tr>
  <tr>
    <td></td>
    <td>backend_size</td>
    <td>Root volume size (GB) on chef-backend instance</td>
    <td>integer</td>
    <td>40</td>
  </tr>
  <tr>
    <td></td>
    <td>backend_term</td>
    <td>Root volume delete on chef-backend instance termination</td>
    <td>boolean</td>
    <td>true</td>
  </tr>
  <tr>
    <td></td>
    <td>backend_type</td>
    <td>Root volume type on chef-backend instance</td>
    <td>string</td>
    <td>gp2</td>
  </tr>
  <tr>
    <td></td>
    <td>ebs_optimized</td>
    <td>Deploy EBS optimized root volume</td>
    <td>boolean</td>
    <td>true</td>
  </tr>
  <tr>
    <td></td>
    <td>frontend_flavor</td>
    <td>AWS instance type for chef-server-core</td>
    <td>string</td>
    <td>m4.large</td>
  </tr>
  <tr>
    <td></td>
    <td>frontend_iops</td>
    <td>Root volume IOPs on chef-server-core instance (`io1`).</td>
    <td>integer</td>
    <td>0</td>
  </tr>
  <tr>
    <td></td>
    <td>frontend_public</td>
    <td>Associate public IP to chef-server-core instance</td>
    <td></td>
    <td>true</td>
  </tr>
  <tr>
    <td></td>
    <td>frontend_size</td>
    <td>Root volume size (GB) on chef-server-core instance</td>
    <td>integer</td>
    <td>40</td>
  </tr>
  <tr>
    <td></td>
    <td>frontend_term</td>
    <td>Root volume delete on chef-server-core instance termination</td>
    <td></td>
    <td>true</td>
  </tr>
  <tr>
    <td></td>
    <td>frontend_type</td>
    <td>Root volume type on chef-server-core instance</td>
    <td>string</td>
    <td>gp2</td>
  </tr>
  <tr>
    <td></td>
    <td>tags_desc</td>
    <td>Description name tag for instances.</td>
    <td></td>
    <td>Created using Terraform</td>
  </tr>
  <tr>
    <td>instance_hostname</td>
    <td></td>
    <td>AWS instance base hostname</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>backend</td>
    <td>Chef backend base hostname</td>
    <td>string</td>
    <td>chefbe</td>
  </tr>
  <tr>
    <td></td>
    <td>frontend</td>
    <td>Chef server core base hostname</td>
    <td>string</td>
    <td>chefbe</td>
  </tr>
  <tr>
    <td>instance_keys</td>
    <td></td>
    <td>AWS SSH key settings</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>key_name</td>
    <td>AWS key pair</td>
    <td>string</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>key_file</td>
    <td>Full path to matching private key</td>
    <td>string</td>
    <td></td>
  </tr>
  <tr>
    <td>instance_store</td>
    <td></td>
    <td>AWS instance store settings</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>device</td>
    <td>AWS instance store device name</td>
    <td>string</td>
    <td>xvdb</td>
  </tr>
  <tr>
    <td></td>
    <td>enabled</td>
    <td>Use AWS instance store</td>
    <td>boolean</td>
    <td>true</td>
  </tr>
  <tr>
    <td></td>
    <td>filesystem</td>
    <td>AWS instance store filesystem</td>
    <td>string</td>
    <td>ext4</td>
  </tr>
  <tr>
    <td></td>
    <td>mount</td>
    <td>AWS instance store mount point</td>
    <td>string</td>
    <td>/mnt/xvdb</td>
  </tr>
  <tr>
    <td></td>
    <td>mount_options</td>
    <td>AWS instance store mount options</td>
    <td>string</td>
    <td>defaults,noatime,errors=remount-ro</td>
  </tr>
  <tr>
    <td>domain</td>
    <td></td>
    <td>Domain name</td>
    <td>string</td>
    <td>localdomain</td>
  </tr>
  <tr>
    <td>r53_zones</td>
    <td></td>
    <td>AWS Route53 zone settings</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>internal</td>
    <td>AWS Route53 internal zone ID</td>
    <td>string</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>external</td>
    <td>AWS Route53 external zone ID</td>
    <td>string</td>
    <td></td>
  </tr>
  <tr>
    <td>r53_ttls</td>
    <td></td>
    <td>AWS Route53 TTL settings</td>
    <td>map</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>internal</td>
    <td>Internal record TTL setting</td>
    <td>integer</td>
    <td>180</td>
  </tr>
  <tr>
    <td></td>
    <td>external</td>
    <td>External record TTL setting</td>
    <td>integer</td>
    <td>180</td>
  </tr>
  <tr>
    <td>etcd_path</td>
    <td></td>
    <td>Path to configure ETCD settings</td>
    <td>`/opt/chef-backend/service/etcd/env`</td>
  </tr>
  <tr>
    <td>etcd_settings</td>
    <td></td>
    <td>Map of settings for ETCD configuration. Key is setting name, value is the value</td>
    <td>ETCD_HEARTBEAT_INTERVAL = 600<br>ETCD_ELECTION_TIMEOUT   = 6000<br>ETCD_SNAPSHOT_COUNT     = 5000</td>
  </tr>
  <tr>
    <td>etcd_restart_cmd</td>
    <td></td>
    <td>Command issued to restart ETCD service</td>
    <td>sudo chef-backend-ctl restart etcd</td>
  </tr>
</table>


### AMI map customization

There following variables work in concert with each other to set a number of
required settings ffor this plan to succeed.

* `ami`: Map of `os`-`instance[..._type]`-`provider[region]` to AMI ID 
* `ami_user`: Map of AMI OS to default AMI username
* `os`: String containing OS+Version (i.e. Ubuntu 14.04.x LTS = `ubuntu14`)
* `provider[region]`: AWS region

Normally you will not interract with the `ami` map directly, however if you
want to override the AMI selected take note of the following example.

Example: Use newer AMI for default `ubuntu14` requires a simple `ami` override:

```hcl
ami = {
  ubuntu14-gp2-us-east-1 = "ami-ffffffff"
}
```

Example: Custom AMI user with custom AMI image

```hcl
os = "myos"
ami = {
  myos-gp2-us-east-1 = "ami-ffffffff"
}
ami_user = {
  myos = "someuser"
}
```

Example: Using existing AMIs but with an io1 root volume on chef-backend

```hcl
instance = {
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
```

Defaults in `ami_user` map:

<table>
  <tr>
    <th>Key</th>
    <th>Value</th>
  </tr>
  <tr>
    <td>centos7</td>
    <td>centos</td>
  </tr>
  <tr>
    <td>centos6</td>
    <td>centos</td>
  </tr>
  <tr>
    <td>ubuntu16</td>
    <td>ubuntu</td>
  </tr>
  <tr>
    <td>ubuntu14</td>
    <td>ubuntu</td>
  </tr>
  <tr>
    <td>ubuntu12</td>
    <td>ubuntu</td>
  </tr>
</table>


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

Please refer to the [CHANGELOG.md](CHANGELOG.md)


## License

This is licensed under [the Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0).

