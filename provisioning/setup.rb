require 'chef/provisioning/aws_driver'
with_driver 'aws::us-east-1'

aws_vpc "testjob-margus-vpc" do
  cidr_block "10.0.0.0/24"
  internet_gateway true
  main_routes '0.0.0.0/0' => :internet_gateway
end

aws_subnet "testjob-margus-vpc-subnet" do
  vpc "testjob-margus-vpc"
  cidr_block "10.0.0.0/26"
  availability_zone "us-east-1c"
  map_public_ip_on_launch true
end

aws_subnet "testjob-margus-vpc-subnet-2" do
  vpc "testjob-margus-vpc"
  cidr_block "10.0.0.64/26"
  availability_zone "us-east-1b"
end

aws_rds_subnet_group "testjob-margus-rds-group" do
  description "subnet_group_for_rds"
  subnets ["testjob-margus-vpc-subnet", "testjob-margus-vpc-subnet-2"]
end

with_machine_options :bootstrap_options => {
  instance_type: 't2.micro',
  image_id: 'ami-38de8d2f',
  associate_public_ip_address: true
}

rds_instance = aws_rds_instance "testjob-margus-rds-instance" do
  engine "postgres"
  publicly_accessible false
  db_instance_class "db.t2.micro"
  allocated_storage 5
  master_username "thechief"
  master_user_password "securesecure" # 2x security
  multi_az false
  db_subnet_group_name "testjob-margus-rds-group"
  additional_options(db_name: "gtest", availability_zone: "us-east-1c")
end

num_appservers = 1

machine_batch do
  num_appservers.times do |i|
    machine "testjob-margus-appserver-#{i}" do
      tag 'testjob-machine'
      machine_options bootstrap_options: { subnet: 'testjob-margus-vpc-subnet' }
      if !rds_instance.nil? && !rds_instance.aws_object.nil?
        attribute %w[postgres host], rds_instance.aws_object.endpoint.address
        attribute %w[postgres port], rds_instance.aws_object.endpoint.port
      end
      recipe 'postgresql::client'
      role 'appserver'
    end
  end
end

lb = load_balancer "testjob-margus-elb" do
  machines (0..(num_appservers-1)).map { |i| "testjob-margus-appserver-#{i}" }
  load_balancer_options(
    lazy do
      {
        listeners: [{
          port: 80,
          protocol: :http,
          instance_port: 80,
          instance_protocol: :http
        }],
        health_check: {
          healthy_threshold:    2,
          unhealthy_threshold:  4,
          interval:             12,
          timeout:              5,
          target:               "HTTP:80/"
        },
        scheme: "internet-facing",
        subnets: "testjob-margus-vpc-subnet"
     }
    end
  )
end

#puts lb.inspect
#puts lb.aws_object.dns_name unless lb.nil?
