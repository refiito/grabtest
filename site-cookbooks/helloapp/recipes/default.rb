include_recipe "nginx"
include_recipe "golang"

file "#{node['nginx']['default_root']}/index.html" do
  content 'Just a placeholder for now'
end

file "#{node['nginx']['default_root']}/test.html" do
  content <<-TEXT
    #{node['postgres']['host']}
    #{node['postgres']['port']}
  TEXT
end
