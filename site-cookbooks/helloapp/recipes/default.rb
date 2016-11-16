include_recipe "nginx"
include_recipe "golang"

git "/opt/testapp" do
  repository "https://github.com/refiito/testapp.git"
  action :sync
end

bash 'compile-app' do
  environment ({
    'GOROOT' => "#{node['go']['install_dir']}/go",
    'GOBIN'  => '$GOROOT/bin',
    'GOPATH' => '/opt/go'
  })
  code "cd /opt/testapp && /usr/local/go/bin/go get && /usr/local/go/bin/go build -o testapp"
  action :run
  only_if {not ::File.exist?('/opt/testapp/testapp')}
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
