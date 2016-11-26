include_recipe "nginx"
include_recipe "golang"

# setting used paths
testapp_location = node['testapp']['install_dir']
testapp_config_location = node['testapp']['config_location']
testapp_binary_location = node['testapp']['binary_location']
goroot_location = ::File.expand_path("go", node['go']['install_dir'])
goexec_location = ::File.expand_path("bin/go", goroot_location)
gobin_location = node['go']['gobin']
gopath_location = node['go']['gopath']

# let's sync the testapp code
git testapp_location do
  repository "https://github.com/refiito/testapp.git"
  action :sync
end

# compile, if needed
bash 'compile-app' do
  environment ({
    'GOROOT' => goroot_location,
    'GOBIN'  => gobin_location,
    'GOPATH' => gopath_location
  })
  code "cd #{testapp_location} && #{goexec_location} get && #{goexec_location} build -o #{testapp_binary_location}"
  action :run
  only_if {not ::File.exist?('/opt/testapp/testapp')}
end

# create the proper config file, used later by systemd unit
file testapp_config_location do
  content <<-CONF
DB="host=#{node['postgres']['host']} port=#{node['postgres']['port']} dbname=gtest user=thechief password=securesecure sslmode=require"
CONF
end

# creating systemd unit for testapp
systemd_unit "testapp.service" do
  enabled true
  content <<-CONF
[Unit]
Description=testapp
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
EnvironmentFile=#{testapp_config_location}
WorkingDirectory=#{testapp_location}
ExecStart=-#{testapp_binary_location}
Restart=on-failure
LimitNOFILE=10000

[Install]
WantedBy=multi-user.target
Alias=testapp.service
CONF
  action :create
end

# giving chef the control over testapp service
service "testapp" do
  provider Chef::Provider::Service::Systemd
  supports status: true, restart: true
  action :start
end

# as we're supposed to run only one service per host, overriding default nginx conf with the one from this recipe
resources("template[#{node['nginx']['dir']}/sites-available/default]").cookbook 'helloapp'
