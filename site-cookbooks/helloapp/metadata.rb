name              'helloapp'
version           '1.0'

recipe 'helloapp', 'Sets up Hello World App'

depends 'nginx', '~> 2.7.6'
depends 'golang', '~> 1.7.0'
supports 'ubuntu'

attribute 'postgres/host',
  :display_name => 'DB host',
  :default => nil

attribute 'postgres/port',
  :display_name => 'DB port',
  :default => nil

attribute 'postgres/user',
  :display_name => 'DB user',
  :default => nil

attribute 'postgres/database',
  :display_name => 'DB database',
  :default => nil