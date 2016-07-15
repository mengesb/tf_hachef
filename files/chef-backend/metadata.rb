name 'chef-backend'
maintainer 'Brian Menges'
maintainer_email 'mengesb@users.noreply.github.com'
license 'Apache 2.0'
description 'Installs/Configures chef-backend'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'

depends 'chef-ingredient', '>= 0.18.4'

recipe 'leader', 'Installs chef-backend leader node'
recipe 'follower', 'Installs chef-backend follower node (requires leader)'

%w(redhat centos debian ubuntu amazon).each do |os|
  supports os
end

source_url 'https://github.com/mengesb/chef-backend' if respond_to?(:source_url)
issues_url 'https://github.com/mengesb/chef-backend/issues' if respond_to?(:issues_url)
