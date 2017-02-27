tf_hachef CHANGELOG
===================

This file is used to list changes made in each version of the tf_hachef Terraform plan.

v0.2.10 (2017-02-23)
--------------------
- Fixed typo in a warning message relating to accepting Chef license

v0.2.9 (2016-10-29)
-------------------
- Added ETCD tunable variables and implementation
- Update `private_key` for `connection` to use `${file()}` interpolation

v0.2.8 (2016-10-28)
-------------------
- Updated repo structure to prepare for multiple providers and plans per provider feature set.
- Documentation updates

v0.2.7 (2016-09-20)
-------------------
- Updated chef-cookbook script to pin system cookbook to `0.11.0`: xhost-cookbooks/system#49
- Update syntax; `template_file` resource is deprecated, updated to `data` source

v0.2.6 (2016-08-11)
-------------------
- Updated root device to use gp2 on backends
- Added map `instance_store` with reasonable defaults
- Now using local node instance storage for backends
- Large documentation overhaul

v0.2.5 (2016-08-10)
-------------------
- Adding `postgresql.md5_auth_cidr_addresses` to `chef-backend.rb` before
joining cluster no longer breaks chef-backend
- attributes-json.tpl -> backend-attributes-json.tpl for consistency

v0.2.4 (2016-08-10)
-------------------
- Fix for #14

v0.2.3 (2016-08-10)
-------------------
- Breakup `chef` map into `chef_backend`, `chef_client`, `chef_mlsa`,
`chef_org`, `chef_server`, and `chef_user` variables
- Changes to supporting documentation

v0.2.2 (2016-08-09)
-------------------
- Fix for #7
- Fix for #8

v0.2.1 (2016-08-08)
-------------------
- Clarification in [README.md](README.md)
- Multiple AZs are not required, however server counts ARE required

v0.2.0 (2016-08-08)
-------------------
- Overhaul on code (nearly complete re-write)
- Updated syntax for (most) Terraform 0.7.0 constructs
- NOTE: Leaving `template` in place of `data` source due to `count` absence on
`data` source
- Removed a number of files

v0.1.1 (2016-07-15)
-------------------
- Documentation work
- Fix [.gitignore](.gitignore) to ignore all `terraform.tfstate*` files

v0.1.0 (2016-07-15)
-------------------
- Initial commit

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
