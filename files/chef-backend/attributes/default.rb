#
# Cookbook Name:: chef-backend
# Attributes:: default
#
# Copyright:: Copyright (c) 2016 Brian Menges
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
default['chef-backend']['accept_license'] = false
default['chef-backend']['channel'] = :stable
default['chef-backend']['ipaddress'] = node['ipaddress']
default['chef-backend']['leader'] = true
default['chef-backend']['leader_ipaddress'] = nil
default['chef-backend']['package_source'] = nil
default['chef-backend']['secrets_file'] = nil
default['chef-backend']['version'] = nil

#
# Tunables
#
# For a complete list see:
# https://docs.chef.io/install_backend.html
#
default['chef-backend']['configuration'] = nil
