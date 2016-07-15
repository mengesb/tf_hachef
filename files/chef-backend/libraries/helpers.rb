# Reference: https://github.com/chef-cookbooks/chef-server/blob/master/libraries/helpers.rb
module ChefBackendCookbook
  module Helpers
    def api_fqdn_available?
      return false if node['chef-backend'].nil?
      return false if node['chef-backend']['api_fqdn'].nil?
      !node['chef-backend']['api_fqdn'].empty?
    end

    def api_fqdn_resolves?
      ChefIngredientCookbook::Helpers.fqdn_resolves?(
        node['chef-backend']['api_fqdn']
      )
    end

    def repair_api_fqdn
      fe = Chef::Util::FileEdit.new('/etc/hosts')
      fe.insert_line_if_no_match(/#{node['chef-backend']['api_fqdn']}/,
        "127.0.0.1 #{node['chef-backend']['api_fqdn']}")
      fe.write_file
    end
  end
end
