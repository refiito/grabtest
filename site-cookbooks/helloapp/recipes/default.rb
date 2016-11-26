include_recipe "nginx"
include_recipe "golang"

git "/opt/testapp" do
  repository "https://github.com/refiito/testapp.git"
  action :sync
end

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

file "/opt/testapp/testapp.conf" do
  content <<-CONF
DB="host=#{node['postgres']['host']} port=#{node['postgres']['port']} dbname=gtest user=thechief password=securesecure sslmode=require"
CONF
end

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

service "testapp" do
  provider Chef::Provider::Service::Systemd
  supports status: true, restart: true
  action :start
end

file "#{node['nginx']['default_root']}/index.html" do
  content 'Just a placeholder for now'
end

file "#{node['nginx']['default_root']}/test.html" do
  content <<-TEXT
    #{node['postgres']['host']}
    #{node['postgres']['port']}
  TEXT
end
