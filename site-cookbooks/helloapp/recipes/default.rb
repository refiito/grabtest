include_recipe "nginx"
include_recipe "golang"

# let's sync the testapp code
git "/opt/testapp" do
  repository "https://github.com/refiito/testapp.git"
  action :sync
end

# compile, if needed
bash 'compile-app' do
  environment ({
    'GOROOT' => "#{node['go']['install_dir']}/go",
    'GOBIN'  => '/opt/testapp/bin',
    'GOPATH' => '/opt/go'
  })
  code "cd /opt/testapp && /usr/local/go/bin/go get && /usr/local/go/bin/go build -o testapp"
  action :run
  only_if {not ::File.exist?('/opt/testapp/testapp')}
end

# create the proper config file, used later by systemd unit
file "/opt/testapp/testapp.conf" do
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
EnvironmentFile=/opt/testapp/testapp.conf
WorkingDirectory=/opt/testapp
ExecStart=-/opt/testapp/testapp
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
