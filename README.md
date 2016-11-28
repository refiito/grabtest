## Test task ##

### Initial assumptions ###

AWS access has been configured (~/.aws/config and ~/.aws/credentials present), ruby and bundler present in the system

### What does this do? ###

The recipes/provisioner will set up a set of machines and configure the network to serve a "hello world" app (see: https://github.com/refiito/testapp)
Setup consists of:
  - VPC, 2 subnets (as seems RDS would like to have 2 subnets)
  - A RDS instance running postgres
  - A load balancer for serving the final application
  - A machine to clone, compile, configure and run the application

### How? ###
Chef is running in Zero/Standalone mode, so, to make this work:
  - Run bundle `bundle install`
  - Run the provisioning script `bundle exec chef-client -z provisioning/setup.rb`

There's a deployed setup to click through at http://testjob-margus-elb-1506669016.us-east-1.elb.amazonaws.com
