default['testapp']['install_dir'] = '/opt/testapp'
default['testapp']['config_location'] = ::File.expand_path("testapp.conf", node['testapp']['install_dir'])
default['testapp']['binary_location'] = ::File.expand_path("testapp", node['testapp']['install_dir'])