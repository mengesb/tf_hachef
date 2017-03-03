# enterprise

This Terraform module is designed to instantiate a high-availability Chef server cluster. It's a variant of **[route53_ssl]** that is designed to be consumed as a module.

[route53_ssl]: https://github.com/kevindickerson/tf_hachef/tree/master/providers/aws/route53_ssl

## Example

This module is designed to be consumed using Terraform's `module` resource.

### To use this module

Create your own module, then use a `module` resource call to consume tf_hachef's **enterprise** module.

### example.tf
```ruby
module "tf_hachef" {
  source = "git@github.com:kevindickerson/tf_hachef.git?ref=v0.3.0//providers/aws/enterprise"

  provider = {
    access_key = ""
    region = "us-west-2"
    secret_key = ""
  }

  r53_zones = {
    external = "Z1P1W012345678"
    internal = "Z1P1W012345679"
  }

  # etc...
}
```

## Contributors

* [Kevin Dickerson, Loom](https://loom.technology)
* [Brian Menges](https://github.com/mengesb)
