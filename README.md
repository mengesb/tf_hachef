# tf_hachef

This terraform plan makes use of chef-backend and chef-server-core to create a
Chef HA architecture. In order to support multiple providers and various
feature sets based upon provider this repo has a tree structure to help you
choose the right plan based on certain assumptions.


# Providers

The following providers are currently supported:

* AWS


# Plans

The following plans exist in this repo:

* AWS w/valid SSL and Route53 internal/external zones - [providers/aws/route53_ssl/README.md](providers/aws/route53_ssl/README.md)


# Tree navigation

* providers
  * aws
    * route53_ssl
  * ... future provider
    * ... future feature set


## Usage


### Module

Usage as a module has not been tested, however in Terraform 0.7.0+ many things
are first-class which were not before. Choose to run this way at your own risk


### Directly

1. Clone this repo: `git clone https://github.com/mengesb/tf_hachef.git`
2. Navigate to the correct plan in the provider tree.
3. Make a local terraform.tfvars file: `cp terraform.tfvars.example terraform.tfvars`
4. Edit `terraform.tfvars` with your editor of choice, ensuring
`var.chef["accept_mlsa"]` is set to `true`
5. Test the plan: `terraform plan`
6. Apply the plan: `terraform apply`


## Recommendations

The defaults set forth in the `variables.tf` file have been set for good reason.
Please note that a good amount of testing went into defining these defaults and
necessary inputs are defined, for your convenience in `terraform.tfvars.example`
per plan.


## Contributors

* [Brian Menges](https://github.com/mengesb)
* [Kevin Dickerson, Loom](https://loom.technology)

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
