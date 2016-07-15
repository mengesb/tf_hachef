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

chef_ingredient 'chef-backend' do
  channel node['chef-backend']['channel'].to_sym
  version node['chef-backend']['version'] unless node['chef-backend']['version'].nil?
  package_source node['chef-backend']['package_source']
  accept_license node['chef-backend']['accept_license']
  config <<-EOS
publish_address "#{node['chef-backend']['ipaddress']}"
#{node['chef-backend']['configuration']}
EOS
  action :upgrade
end

execute 'create_cluster' do
  command 'chef-backend-ctl create-cluster --accept-license --yes'
  action :nothing
  only_if { node['chef-backend']['accept_license'] == true }
  not_if { File.exist?("#{Chef::Config[:file_cache_path]}/chef-backend-secrets.json") }
end

ingredient_config 'chef-backend' do
  notifies :run, 'execute[create_cluster]', :immediately
  notifies :reconfigure, 'chef_ingredient[chef-backend]', :immediately
end
