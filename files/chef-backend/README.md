chef-backend Cookbook
=======================

[![Build Status](https://travis-ci.org/mengesb/chef-backend.svg?branch=master)](https://travis-ci.org/mengesb/chef-backend)
[![Cookbook Version](https://img.shields.io/cookbook/v/chef-backend.svg)](https://supermarket.chef.io/cookbooks/chef-backend)

This cookbook configures a system to be a Chef backend Server. It will install
the appropriate platform-specific backend Omnibus package from Package Cloud
and perform the initial configuration.


Requirements
------------
This cookbook is tested with Chef (client) 12. It may work with or
without modification on earlier versions of Chef, but Chef 12 is
recommended.

## Cookbooks

* chef-ingredient cookbook

## Platform

This cookbook is tested on the following platforms using the
[Test Kitchen](http://kitchen.ci) `.kitchen.yml` in the repository.

- Ubuntu 14.04 64-bit

By default this cookbook is designed to setup and create the leader node for
the chef backend cluster. To setup a follower node of the cluster, update
the following options:

* `node['chef-backend']['leader_ipaddress']`
* `node['chef-backend']['secrets_file']`
* `node['chef-backend']['leader'] = false`

Of course be sure to accept the Chef MLSA license agreement.

Attributes
----------

#### chef-backend::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['chef-backend']['accept_license']</tt></td>
    <td>Boolean</td>
    <td>Indication that you accept the Chef MLSA</td>
    <td><tt>false</tt></td>
  </tr>
  <tr>
    <td><tt>['chef-backend']['channel']</tt></td>
    <td>Symbol</td>
    <td>Repo channel to source package from</td>
    <td><tt>:stable</tt></td>
  </tr>
  <tr>
    <td><tt>['chef-backend']['ipaddress']</tt></td>
    <td>String</td>
    <td>This node's IP address</td>
    <td><tt>node['ipaddress']</tt></td>
  </tr>
  <tr>
    <td><tt>['chef-backend ']['leader']</tt></td>
    <td>Boolean</td>
    <td>Leader node for initial configuration</td>
    <td><tt>true</tt></td>
  </tr>
  <tr>
    <td><tt>['chef-backend']['leader_ipaddress']</tt></td>
    <td>String</td>
    <td>Leader node's IP address</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['chef-backend']['package_source']</tt></td>
    <td>String</td>
    <td>Anything other than package cloud</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['chef-backend']['secrets_file']</tt></td>
    <td>String</td>
    <td>Path to chef-backend-secrets.json file</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['chef-backend']['version']</tt></td>
    <td>String</td>
    <td>What version of backend to install</td>
    <td><tt>nil</tt></td>
  </tr>
</table>

Usage
-----
#### chef-backend::default

Add chef-backend to your run list and accept the license agreement by setting
`node['chef-backend']['accept_license'] = true`

# License and Authors

* Author: Brian Menges <mengesb@users.noreply.github.com>
* Copyright 2016, Brian Menges

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
