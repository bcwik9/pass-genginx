require_relative '../template'
require_relative '../parameter'
require_relative '../ec2_resource'
require_relative '../security_group_resource'
require_relative '../eb_application_resource'
require_relative '../eb_application_version_resource'
require_relative '../eb_config_template_resource'
require_relative '../eb_environment_resource'
require_relative '../elasticache_cluster_resource'
require_relative '../elasticache_security_group_resource'
require_relative '../elasticache_security_group_ingress_resource'
require_relative '../iam_profile_resource'
require_relative '../iam_policy_resource'
require_relative '../iam_role_resource'
require_relative '../wait_condition_resource'
require_relative '../wait_handle_resource'
require_relative '../cloudformation_init'
require_relative '../autoscaling_group_resource'
require_relative '../autoscaling_policy_resource'
require_relative '../elb_balancer_resource'
require_relative '../cloudwatch_alarm_resource'
require_relative '../rds_resource'
require_relative '../rds_security_group_resource'
require_relative '../vpc_resource'
require_relative '../subnet_resource'
require_relative '../route_table_resource'
require_relative '../route_resource'
require_relative '../internet_gateway_resource'
require_relative '../vpc_gateway_attachment_resource'
require_relative '../network_acl_resource'
require_relative '../network_acl_entry_resource'
require_relative '../subnet_network_acl_association_resource'
require_relative '../subnet_route_table_association_resource'
require_relative '../rds_subnet_group_resource'
require_relative '../security_group_access'

# a simple ec2 server with security group
# asks for a SSH key as only parameter
# ports open: 22 (SSH), 80 and 443 (HTTP/HTTPS)
def basic_ec2_with_sg_template
  template = AwsTemplate.new(:description => 'Basic cloudformation template with a single ec2 instance and security group with ports 22, 80, and 443 open')
  
  # user will pass in their SSH key at runtime
  ssh_key_param = AwsParameter.new(:logical_id => "SshKeyName", :description => "Name of an existing EC2 KeyPair to enable SSH access to the web server", :type => "AWS::EC2::KeyPair::KeyName")
  
  # basic security group with ports 22, 80, and 443 open by default
  sg = AwsSecurityGroup.new
  
  ec2 = AwsEc2Instance.new
  ec2.add_security_group sg # associate security group with ec2 instance
  ec2.add_property :KeyName, ssh_key_param.get_reference # add ssh key param

  # add resources and parameter to our template
  template.add_resources [ec2, sg]
  template.add_parameter ssh_key_param
  
  return template
end

# create an elastic beanstalk Rails application from a project zip stored in S3
def elasticbeanstalk_app_template
  # parameters
  # prompt user for SECRET_KEY_BASE
  secret_key_param = AwsParameter.new(:logical_id => "SecretKeyBase", :description => "Rails secret key base for production", :default => "CHANGEME")
  secret_key_param.add_option(:minLength, 1)
  
  # prompt user for S3 bucket name
  bucket_name_param = AwsParameter.new(:logical_id => "BucketName", :description => "S3 Bucket name where Rails project is stored")
  bucket_name_param.add_option(:minLength, 1)

  # prompt user for Rails project zip file
  project_zip_param = AwsParameter.new(:logical_id => "ProjectZip", :description => "Rails project zip file")
  project_zip_param.add_option(:minLength, 1)
  
  eb_app = AwsElasticBeanstalkApplication.new

  eb_version = AwsElasticBeanstalkApplicationVersion.new
  eb_version.set_application_name eb_app.get_reference
  # application source is passed in via user params
  eb_version.set_source bucket_name_param.get_reference, project_zip_param.get_reference

  eb_config = AwsElasticBeanstalkConfigurationTemplate.new
  eb_config.set_application_name eb_app.get_reference
  eb_config.enable_single_instance
  eb_config.set_instance_type 't2.micro'
  eb_config.set_stack_name "64bit Amazon Linux 2015.03 v1.3.0 running Ruby 2.2 (Passenger Standalone)"
  # let rails access the secret key base, which is provided via user params
  # required for running in production
  eb_config.set_option "aws:elasticbeanstalk:application:environment", "SECRET_KEY_BASE", secret_key_param.get_reference

  eb_env = AwsElasticBeanstalkEnvironment.new
  eb_env.set_application_name eb_app.get_reference
  eb_env.set_template_name eb_config.get_reference
  eb_env.set_version_label eb_version.get_reference
  
  # create a blank template and add all the resources/parameters we need
  template = AwsTemplate.new(:description => 'Create an elasticbeanstalk app from a rails zip file stored in s3')
  template.add_resources [eb_app, eb_version, eb_config, eb_env]
  template.add_parameters [secret_key_param, bucket_name_param, project_zip_param]

  return template
end

def ec2_with_elasticache_template
  # elasticache with redis currently has poor support in cloudformation
  # we need to create a IAM role that gives permission to our EC2
  # instance to query for the elasticache endpoint
  iam_role = AwsIamRole.new
  iam_policy = AwsIamPolicy.new(:name => iam_role.logical_id)
  iam_policy.add_role iam_role
  iam_profile = AwsIamInstanceProfile.new
  iam_profile.add_role iam_role

  ssh_key_param = AwsParameter.new(:logical_id => "SshKeyName", :description => "Name of an existing EC2 KeyPair to enable SSH access to the web server", :type => "AWS::EC2::KeyPair::KeyName")
  
  redis_sg = AwsElastiCacheSecurityGroup.new
  
  redis_ec = AwsElastiCacheCluster.new
  redis_ec.add_property :CacheSecurityGroupNames, [redis_sg.get_reference]
  
  ec2_sg = AwsSecurityGroup.new
  
  ec2 = AwsEc2Instance.new
  ec2.add_security_group ec2_sg
  ec2.set_image_id 'ami-26b9834e'
  # add commands to install aws command line tools
  ec2.commands += [
                   "sudo apt-get install -y awscli", "\n"
                  ]
  # add commands to log Redis cluster endpoint
  ec2.commands += [
                   "aws elasticache describe-cache-clusters ",
                   " --cache-cluster-id ",
                   redis_ec.get_reference,
                   " --show-cache-node-info --region ",
                   AwsTemplate.region_reference,
                   " > /var/log/redis_cluster.log", "\n"
                  ]
  ec2.add_property :IamInstanceProfile, iam_profile.get_reference
  ec2.add_property :KeyName, ssh_key_param.get_reference
  
  redis_ingress = AwsElastiCacheSecurityGroupIngress.new(:cache_security_group => redis_sg, :ec2_security_group => ec2_sg)

  template = AwsTemplate.new(:description => 'creates a ec2 instance which has access to a redis elasticache cluster')
  template.add_resources [redis_sg, redis_ec, ec2_sg, ec2, redis_ingress, iam_role, iam_policy, iam_profile]
  template.add_parameter ssh_key_param
  return template
end

def ec2_with_cfn_init_template
  ssh_key_param = AwsParameter.new(:logical_id => "SshKeyName", :description => "Name of an existing EC2 KeyPair to enable SSH access to the web server", :type => "AWS::EC2::KeyPair::KeyName")
  
  ec2_sg = AwsSecurityGroup.new
  
  ec2_config = AwsCloudFormationInit.new
  ec2_config.add_config(
                        # create some files from content and the web
                        :files => [
                                   {
                                     :content => 'hello again, world!'
                                   },
                                   {
                                     :source => 'https://raw.githubusercontent.com/bcwik9/ScriptsNStuff/master/add_nginx_servers.rb'
                                   }
                                  ],
                        # install git and emacs
                        :packages => [
                                      {
                                        :package => 'git'
                                      },
                                      {
                                        :package => 'emacs'
                                      }
                                     ],
                        # pull a project down from github
                        :sources => [
                                     {
                                       :url => 'https://github.com/bcwik9/bcwik-site/tarball/master',
                                       :dir => '/etc/myApp'
                                     }
                                    ],
                        # execute bash commands
                        :commands => [
                                      {
                                        :command => 'echo "hello world!" > /var/log/helloworld.log'
                                      }
                                     ]
                        )
  
  ec2 = AwsEc2Instance.new
  ec2.add_security_group ec2_sg
  ec2.set_image_id 'ami-26b9834e' # bitnami ruby stack
  ec2.metadata = ec2_config.to_h
  ec2.add_property :KeyName, ssh_key_param.get_reference
  # update
  ec2.commands += ['sudo apt-get update -y', "\n"]
  # commands to install cfn-init
  ec2.commands += [
                   'sudo apt-get install -y python-setuptools', "\n",
                   'easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz', "\n"
                  ]
  # run cfn-init. this kicks off the config we created before
  ec2.commands += [
                   "`which cfn-init` --region ",
                   AwsTemplate.region_reference,
                   ' -s ',
                   AwsTemplate.stack_name_reference,
                   ' -r ',
                   ec2.logical_id, "\n"
                  ]

  template = AwsTemplate.new(:description => 'Create a single EC2 instance to demonstrate the use of cfn-init. download a github project, create files, and execute commands')
  template.add_resources [ec2, ec2_sg]
  template.add_parameter ssh_key_param
  return template
end

def ec2_codedeploy_template
  # these tags are what let codedeploy know which instances to deploy to
  codedeploy_tags = [{ :Key => 'defaultCodedeployKey', :Value => 'defaultCodedeployValue' }]
  
  ssh_key_param = AwsParameter.new(:logical_id => "SshKeyName", :description => "Name of an existing EC2 KeyPair to enable SSH access to the web server", :type => "AWS::EC2::KeyPair::KeyName")

  instance_role = AwsIamRole.new(:logical_id => 'IamInstanceRole')
  instance_policy = AwsIamPolicy.new(:name => instance_role.logical_id, :action => ["autoscaling:Describe*", "cloudformation:Describe*", "cloudformation:GetTemplate", "s3:Get*"], :logical_id => 'IamInstancePolicy')
  instance_policy.add_role instance_role
  instance_profile = AwsIamInstanceProfile.new(:logical_id => 'IamInstanceProfile')
  instance_profile.add_role instance_role
  
  codedeploy_role = AwsIamRole.new(
                                   :logical_id => 'codedeployRole',
                                   :service => [
                                                'codedeploy.us-east-1.amazonaws.com',
                                                'codedeploy.us-west-2.amazonaws.com'                                      
                                               ],
                                   :sid => '1'
                                   )
  codedeploy_policy = AwsIamPolicy.new(
                                       :logical_id => 'codedeployPolicy',
                                       :name => 'CodeDeployPolicy',
                                       :action => ["autoscaling:CompleteLifecycleAction", "autoscaling:DeleteLifecycleHook", "autoscaling:DescribeLifecycleHooks", "autoscaling:DescribeAutoScalingGroups", "autoscaling:PutLifecycleHook", "autoscaling:RecordLifecycleActionHeartbeat", "ec2:Describe*"]
                                       )
  codedeploy_policy.add_role codedeploy_role

  # create new wait handle and wait condition (15 minute timeout)
  handle = AwsWaitHandle.new
  cond = AwsWaitCondition.new(:timeout => 900)

  ec2_sg = AwsSecurityGroup.new

  ec2_config = AwsCloudFormationInit.new
  ec2_config.add_config(
                        :services => [
                                      {
                                        :name => 'sysvint',
                                        'codedeploy-agent' => {
                                          :enabled => true,
                                          :ensureRunning => true
                                        }
                                      }
                                     ]
                        )
  
  ec2 = AwsEc2Instance.new
  ec2.set_image_id 'ami-26b9834e' # bitnami AMI
  ec2.add_security_group ec2_sg
  ec2.add_property :KeyName, ssh_key_param.get_reference
  ec2.add_property :Tags, codedeploy_tags
  ec2.add_property :IamInstanceProfile, instance_profile.get_reference
  ec2.metadata = ec2_config.to_h
  # update
  ec2.commands += [ 'sudo apt-get update -y', "\n" ]
  # stop all services that bitnami installed
  ec2.commands += [ 'sudo /opt/bitnami/ctlscript.sh stop', "\n" ]
  # install aws cli tools and ruby and libsqlite3-dev
  ec2.commands += [ "sudo apt-get install -y awscli ruby2.0 libsqlite3-dev", "\n" ]
  #install codedeploy agent
  ec2.commands += [
                   "sudo aws s3 cp s3://aws-codedeploy-",
                   AwsTemplate.region_reference,
                   "/latest/install /tmp/ --region ",
                   AwsTemplate.region_reference, "\n",
                   'sudo chmod +x /tmp/install', "\n",
                   'sudo -i /tmp/install auto', "\n"
                  ]
  # commands to install cfn-init
  ec2.commands += [
                   'sudo apt-get install -y python-setuptools', "\n",
                   'easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz', "\n"
                  ]  
  # run cfn-init. this kicks off the config we created before
  ec2.commands += [
                   "`which cfn-init` --region ",
                   AwsTemplate.region_reference,
                   ' -s ',
                   AwsTemplate.stack_name_reference,
                   ' -r ',
                   ec2.logical_id, "\n"
                  ]
  # notify that everything is done
  ec2.commands += [
                   "curl -X PUT -H 'Content-Type:' --data-binary '{\"Status\" : \"SUCCESS\",",
                   "\"Reason\" : \"Server is ready\",",
                   "\"UniqueId\" : \"#{ec2.logical_id}\",",
                   "\"Data\" : \"Done\"}' ",
                   "\"", handle.get_reference,"\"\n"
                  ]
  
  # associate wait condition/handle and ec2
  cond.set_handle handle
  cond.depends_on = ec2.logical_id

  template = AwsTemplate.new(:description => "ec2 instance ready to be updated via codedeploy")
  template.add_resources [ec2, ec2_sg, instance_role, instance_profile, instance_policy, codedeploy_role, codedeploy_policy, handle, cond]
  template.add_parameter ssh_key_param
  return template
end

def autoscaling_with_codedeploy_template
  ssh_key_param = AwsParameter.new(:logical_id => "SshKeyName", :description => "Name of an existing EC2 KeyPair to enable SSH access to the web server", :type => "AWS::EC2::KeyPair::KeyName")

  instance_role = AwsIamRole.new(:logical_id => 'IamInstanceRole')
  instance_policy = AwsIamPolicy.new(:name => instance_role.logical_id, :action => ["autoscaling:Describe*", "cloudformation:Describe*", "cloudformation:GetTemplate", "s3:Get*"], :logical_id => 'IamInstancePolicy')
  instance_policy.add_role instance_role
  instance_profile = AwsIamInstanceProfile.new(:logical_id => 'IamInstanceProfile')
  instance_profile.add_role instance_role
  
  codedeploy_role = AwsIamRole.new(
                                   :logical_id => 'codedeployRole',
                                   :service => [
                                                'codedeploy.us-east-1.amazonaws.com',
                                                'codedeploy.us-west-2.amazonaws.com'
                                               ],
                                   :sid => '1'
                                   )
  codedeploy_policy = AwsIamPolicy.new(
                                       :logical_id => 'codedeployPolicy',
                                       :name => 'CodeDeployPolicy',
                                       :action => ["autoscaling:CompleteLifecycleAction", "autoscaling:DeleteLifecycleHook", "autoscaling:DescribeLifecycleHooks", "autoscaling:DescribeAutoScalingGroups", "autoscaling:PutLifecycleHook", "autoscaling:RecordLifecycleActionHeartbeat", "ec2:Describe*"]
                                       )
  codedeploy_policy.add_role codedeploy_role

  # create new wait handle and wait condition (15 minute timeout)
  handle = AwsWaitHandle.new
  cond = AwsWaitCondition.new(:timeout => 900)

  ec2_sg = AwsSecurityGroup.new

  #ec2_config = AwsCloudFormationInit.new
  #ec2_config.add_config(
  #                      :services => [
  #                                    {
  #                                      :name => 'sysvint',
  #                                      'codedeploy-agent' => {
  #                                        :enabled => true,
  #                                        :ensureRunning => true
  #                                      }
  #                                    }
  #                                   ]
  #                      )

  ec2 = AwsEc2Instance.new # pretend this is a launch config
  ec2.type = 'AWS::AutoScaling::LaunchConfiguration'
  ec2.set_image_id 'ami-26b9834e' # bitnami AMI
  ec2.add_security_group ec2_sg
  ec2.add_property :KeyName, ssh_key_param.get_reference
  #ec2.add_property :Tags, codedeploy_tags
  ec2.add_property :IamInstanceProfile, instance_profile.get_reference
  #ec2.metadata = ec2_config.to_h
  # update
  ec2.commands += [ 'sudo apt-get update -y', "\n" ]
  # stop all services that bitnami installed
  ec2.commands += [ 'sudo /opt/bitnami/ctlscript.sh stop', "\n" ]
  # install aws cli tools and ruby and libsqlite3-dev
  ec2.commands += [ "sudo apt-get install -y awscli ruby2.0 libsqlite3-dev", "\n" ]
  #install codedeploy agent
  ec2.commands += [
                   "sudo aws s3 cp s3://aws-codedeploy-",
                   AwsTemplate.region_reference,
                   "/latest/install /tmp/ --region ",
                   AwsTemplate.region_reference, "\n",
                   'sudo chmod +x /tmp/install', "\n",
                   'sudo -i /tmp/install auto', "\n"
                  ]
  # commands to install cfn-init
  #ec2.commands += [
  #                 'sudo apt-get install -y python-setuptools', "\n",
  #                 'easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz', "\n"
  #                ]
  
  # run cfn-init. this kicks off the config we created before
  #ec2.commands += [
  #                 "`which cfn-init` --region ",
  #                 AwsTemplate.region_reference,
  #                 ' -s ',
  #                 AwsTemplate.stack_name_reference,
  #                 ' -r ',
  #                 ec2.logical_id, "\n"
  #                ]
  # notify that everything is done
  ec2.commands += [
                   "curl -X PUT -H 'Content-Type:' --data-binary '{\"Status\" : \"SUCCESS\",",
                   "\"Reason\" : \"Server is ready\",",
                   "\"UniqueId\" : \"#{ec2.logical_id}\",",
                   "\"Data\" : \"Done\"}' ",
                   "\"", handle.get_reference,"\"\n"
                  ]
  
  lb = AwsElasticLoadBalancer.new
  lb.add_listener(:port => 80)
  lb.add_health_check(:target => 'HTTP:80/')
  scaling_group = AwsAutoScalingGroup.new(:load_balancers => [lb], :launch_config => ec2)
  scaling_group.set_max_size 2
  scaling_policy = AwsAutoScalingPolicy.new(:group => scaling_group)
  alarm = AwsCloudWatchAlarm.new
  alarm.add_alarm_action scaling_policy
  alarm.add_dimension 'AutoScalingGroupName', scaling_group.get_reference
  
  # associate wait condition/handle and ec2
  cond.set_handle handle
  cond.depends_on = ec2.logical_id

  template = AwsTemplate.new(:description => "autoscaling group ready to be updated via codedeploy")
  template.add_resources [ec2, ec2_sg, instance_role, instance_profile, instance_policy, codedeploy_role, codedeploy_policy, handle, cond, lb, scaling_group, scaling_policy, alarm]
  template.add_parameter ssh_key_param
  return template
end

def buster_dev_template
  template = AwsTemplate.new(:description => 'Buster development environment')
  
  # Params
  # user will pass in their SSH key at runtime
  ssh_key_param = AwsParameter.new(:logical_id => "SshKeyName", :description => "Name of an existing EC2 KeyPair to enable SSH access to the web server", :type => "AWS::EC2::KeyPair::KeyName")
  # ask for packages that should be installed via apt-get
  packages_param = AwsParameter.new(:logical_id => 'PackagesToInstall', :description => "Packages to install via 'apt-get install'")
  # ask for github username and password required to clone git repo
  github_param = AwsParameter.new(:logical_id => 'GithubAccount', :description => "Github username and password to clone repository", :default => 'username:password')
  # ask for github branch name
  git_branch_param = AwsParameter.new(:logical_id => 'GithubBranch', :description => "Git branch to clone", :default => 'master')  
  # ask for heroku user email
  heroku_email_param = AwsParameter.new(:logical_id => 'HerokuEmail', :description => "Heroku user email associated with your account")  
  # ask for heroku API key
  heroku_key_param = AwsParameter.new(:logical_id => 'HerokuAPIKey', :description => "Heroku user API key, which can be found under your profile on Heroku website")
  # ask for heroku database user
  heroku_database_user_param = AwsParameter.new(:logical_id => 'HerokuDatabaseUser', :description => "Heroku database user name")
  # ask for heroku database URL
  heroku_database_url_param = AwsParameter.new(:logical_id => 'HerokuDatabaseURL', :description => "Heroku database URL")

  # CodeDeploy
  # these tags are what let codedeploy know which instances to deploy to
  codedeploy_tags = [{ :Key => 'BusterCodedeployKey', :Value => 'BusterCodedeployValue' }]

  instance_role = AwsIamRole.new(:logical_id => 'IamInstanceRole')
  instance_policy = AwsIamPolicy.new(:name => instance_role.logical_id, :action => ["autoscaling:Describe*", "cloudformation:Describe*", "cloudformation:GetTemplate", "s3:Get*"], :logical_id => 'IamInstancePolicy')
  instance_policy.add_role instance_role
  instance_profile = AwsIamInstanceProfile.new(:logical_id => 'IamInstanceProfile')
  instance_profile.add_role instance_role
  codedeploy_role = AwsIamRole.new(
                                   :logical_id => 'codedeployRole',
                                   :service => [
                                                'codedeploy.us-east-1.amazonaws.com',
                                                'codedeploy.us-west-2.amazonaws.com'                                      
                                               ],
                                   :sid => '1'
                                   )
  codedeploy_policy = AwsIamPolicy.new(
                                       :logical_id => 'codedeployPolicy',
                                       :name => 'CodeDeployPolicy',
                                       :action => ["autoscaling:CompleteLifecycleAction", "autoscaling:DeleteLifecycleHook", "autoscaling:DescribeLifecycleHooks", "autoscaling:DescribeAutoScalingGroups", "autoscaling:PutLifecycleHook", "autoscaling:RecordLifecycleActionHeartbeat", "ec2:Describe*"]
                                       )
  codedeploy_policy.add_role codedeploy_role
  
  # create a VPC
  vpc = AwsVpc.new
  internet_gateway = AwsInternetGateway.new
  gateway_attachment = AwsVpcGatewayAttachment.new(vpc: vpc, gateway: internet_gateway)
  subnet_1 = AwsSubnet.new(vpc: vpc, logical_id: 'subnet1', availability_zone: 'us-east-1a')
  subnet_2 = AwsSubnet.new(vpc: vpc, cidr_block: '10.0.1.0/24', logical_id: 'subnet2', availability_zone: 'us-east-1d')
  route_table = AwsRouteTable.new(vpc: vpc)
  route = AwsRoute.new(route_table: route_table)
  route.set_gateway internet_gateway
  route.depends_on  = gateway_attachment.logical_id
  subnet_association = AwsSubnetRouteTableAssociation.new(subnet: subnet_1, route_table: route_table)
  network_acl = AwsNetworkAcl.new(vpc: vpc)
  inbound_acl = AwsNetworkAclEntry.new(network_acl: network_acl, outbound_traffic: false, logical_id: 'inbound')
  outbound_acl = AwsNetworkAclEntry.new(network_acl: network_acl, outbound_traffic: true, logical_id: 'outbound')
  subnet_acl_association = AwsSubnetNetworkAclAssociation.new(network_acl: network_acl, subnet: subnet_1)

  # create new wait handle and wait condition (20 minute timeout)
  handle = AwsWaitHandle.new
  cond = AwsWaitCondition.new(:timeout => 1200)
  
  # basic security group with ports 22, 80, and 443 open by default
  sg = AwsSecurityGroup.new
  sg.add_inbound_access(:from => 3000) # also add 3000 for ruby development
  sg.add_inbound_access(:from => 1080) # also add 1080 for mailcatcher
  sg.add_inbound_access(from: 5432, source_security_group: sg) # allow access to RDS default port
  sg.add_property :VpcId, vpc.get_reference

  # Set up RDS database
  rds = AwsRdsInstance.new
  #rds_sg = rds.add_db_security_group sg
  rds.add_vpc_security_group sg
  rds_endpoint = rds.get_att('Endpoint.Address')
  rds_port = rds.get_att('Endpoint.Port')
  rds_subnet = AwsRdsDbSubnetGroup.new(subnets: [subnet_1, subnet_2])
  rds.add_db_subnet rds_subnet
    
  # ec2 instance
  ec2 = AwsEc2Instance.new
  #ec2.add_security_group sg
  ec2.set_image_id "ami-d05e75b8"
  ec2.set_instance_type "t2.small"
  ec2.add_property :KeyName, ssh_key_param.get_reference
  ec2.add_property :Tags, codedeploy_tags
  ec2.add_property :IamInstanceProfile, instance_profile.get_reference
  ec2.add_property :SubnetId, subnet_1.get_reference
  ec2.add_property :SecurityGroupIds, [sg.get_reference]
  ec2.depends_on = gateway_attachment.logical_id

  # install dependencies and ruby/rvm/rails
  cfn_init_commands = []
  cfn_init_commands += [
                   "export HOME=`pwd`" ,"\n",
                   "wget --no-check-certificate https://raw.githubusercontent.com/bcwik9/ScriptsNStuff/master/setup_dev_server.sh && bash setup_dev_server.sh ", packages_param.get_reference, "\n",
                   "sudo apt-get install -y libqt4-dev nodejs build-essential tcl8.5 libpq-dev qt5-default libqt5webkit5-dev awscli libsqlite3-dev ruby2.0", "\n"
                  ]
  # install redis
  cfn_init_commands += [
                   "sudo apt-get install -y build-essential tcl8.5", "\n",
                   "wget http://download.redis.io/releases/redis-2.8.9.tar.gz", "\n",
                   "tar xzf redis-2.8.9.tar.gz", "\n",
                   "cd redis-2.8.9", "\n",
                   "make", "\n",
                   "sudo make install", "\n",
                   "cd utils", "\n",
                   "sudo ./install_server.sh", "\n"
                  ]
  # set up postgres with a user
  cfn_init_commands += [
                   "echo \"deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main\" > /etc/apt/sources.list.d/pgdg.list", "\n",
                   "wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -", "\n",
                   "sudo apt-get update", "\n",
                   "sudo apt-get install -y postgresql-9.4 postgresql-contrib", "\n",
                   "sudo -iu postgres psql -c \"create role busterapp with superuser createdb login password 'password';\"", "\n"
                  ]
  #install codedeploy agent
  cfn_init_commands += [
                   "sudo aws s3 cp s3://aws-codedeploy-",
                   AwsTemplate.region_reference,
                   "/latest/install /tmp/ --region ",
                   AwsTemplate.region_reference, "\n",
                   'sudo chmod +x /tmp/install', "\n",
                   'sudo -i /tmp/install auto', "\n"
                  ]
  # clone git repo
  cfn_init_commands += [
                   "cd /home/ubuntu", "\n",
                   "bash --login /usr/local/rvm/bin/rvmsudo git clone -b ", git_branch_param.get_reference,
                   " https://", github_param.get_reference,
                   "@github.com/BustrInc/bustr.git", "\n",
                  ]
  # commands to install cfn-init
  ec2.commands += [
                   "export HOME=`pwd`" ,"\n",
                   'sudo apt-get install -y python-setuptools', "\n",
                   'easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz', "\n"
                  ]
  # run cfn-init. this kicks off the config we created before
  ec2.commands += [
                   "`which cfn-init` --region ",
                   AwsTemplate.region_reference,
                   ' -s ',
                   AwsTemplate.stack_name_reference,
                   ' -r ',
                   ec2.logical_id, "\n"
                  ]
  # use rvm to install/use correct ruby version
  cfn_init_commands += [
                   "bash --login /usr/local/rvm/bin/rvm install 2.2.1", "\n",
                   "export PATH=\"$PATH:/usr/local/rvm/bin/rvm\"", "\n",
                   "bash --login /usr/local/rvm/bin/rvm use 2.2.1", "\n"
                  ]
  # set up database initially
  cfn_init_commands += [
                   "cd bustr", "\n",
                   "cp config/application.example.yml config/application.yml", "\n",
                   'sed -i \'s/config\.action_controller\.asset_host/#config\.action_controller\.asset_host/\' config/environments/development.rb', "\n",
                   "bash --login /usr/local/rvm/bin/rvmsudo bundle install", "\n"
                  ]
  # pull in production data from heroku
  cfn_init_commands += [
                   "wget -qO- https://toolbelt.heroku.com/install-ubuntu.sh | sh", "\n",
                   "mv /home/ubuntu/database.yml /home/ubuntu/bustr/config/", "\n",
                   "bash --login /usr/local/rvm/bin/rvmsudo rake db:create db:migrate db:test:prepare assets:precompile", "\n",
                   "sudo -iu postgres psql -c \"create role ", heroku_database_user_param.get_reference ," with superuser login createdb password NULL;\"", "\n",
                   "sudo pg_dump -Fc -d ", heroku_database_url_param.get_reference," > prod_dump.sql", "\n",
                   "sudo pg_restore --verbose --clean --no-acl --no-owner -h ", rds_endpoint, " -U ", rds.username," -d buster_prod prod_dump.sql", "\n",
                   "bash --login /usr/local/rvm/bin/rvmsudo rake db:migrate", "\n"
                  ]
  # run sidekiq/rails server
  cfn_init_commands += [
                   "sudo chmod -R 777 /home/ubuntu/bustr", "\n",
                   "bash --login /usr/local/rvm/bin/rvmsudo bundle exec sidekiq -d -L log/sidekiq.log", "\n",
                   "bash --login /usr/local/rvm/bin/rvmsudo bundle exec rails server -b 0.0.0.0 -d -p 80 > log/server.log", "\n"
                  ]
  # notify that everything is done
  cfn_init_commands += [
                   "curl -X PUT -H 'Content-Type:' --data-binary '{\"Status\" : \"SUCCESS\",",
                   "\"Reason\" : \"Server is ready\",",
                   "\"UniqueId\" : \"#{ec2.logical_id}\",",
                   "\"Data\" : \"Done\"}' ",
                   "\"", handle.get_reference,"\"\n"
                  ]

  # commands to execute when cfn init runs
  database_yml_content = AwsTemplate.join ([
                                            "development:", "\n",
                                            "  adapter: postgresql", "\n",
                                            "  encoding: unicode", "\n",
                                            "  database: buster_prod", "\n",
                                            "  host: ", rds_endpoint, "\n",
                                            "  username: ", rds.username, "\n",
                                            "  password: ", rds.password, "\n",
                                            "\n",
                                            "test:", "\n",
                                            "  adapter: postgresql", "\n",
                                            "  encoding: unicode", "\n",
                                            "  database: buster_test", "\n",
                                            "  host: ", rds_endpoint, "\n",
                                            "  username: ", rds.username, "\n",
                                            "  password: ", rds.password, "\n"
                                           ])
  netrc_content = AwsTemplate.join ([
                                     "machine api.heroku.com", "\n",
                                     "  login ", heroku_email_param.get_reference, "\n",
                                     "  password ", heroku_key_param.get_reference, "\n",
                                     "machine git.heroku.com", "\n",
                                     "  login ", heroku_email_param.get_reference, "\n",
                                     "  password ", heroku_key_param.get_reference, "\n"
                                    ])
  pgpass_content = AwsTemplate.join ([
                                      # buster_prod
                                      rds_endpoint,":",
                                      rds_port, ":",
                                      :buster_prod, ":",
                                      rds.username, ":",
                                      rds.password, "\n",
                                      # buster_test
                                      rds_endpoint,":",
                                      rds_port, ":",
                                      :buster_test, ":",
                                      rds.username, ":",
                                      rds.password, "\n"
                                     ])
  ec2_config = AwsCloudFormationInit.new
  ec2_config.add_config(
                        :files => [{
                                     :content => database_yml_content,
                                     :location => '/home/ubuntu/database.yml'
                                   },
                                   {
                                     :content => pgpass_content,
                                     :location => '/root/.pgpass',
                                     :mode => '000600'
                                   },
                                   {
                                     :content => pgpass_content,
                                     :location => '/home/ubuntu/.pgpass',
                                     :mode => '000600'
                                   },
                                   {
                                     :content => netrc_content,
                                     :location => '/home/ubuntu/.netrc'
                                   }],
                        :services => [
                                      {
                                        :name => 'sysvint',
                                        'codedeploy-agent' => {
                                          :enabled => true,
                                          :ensureRunning => true
                                        }
                                      }
                                     ],
                        :commands => [{
                                        command: (AwsTemplate.join cfn_init_commands)
                                      }]
                        )

  # add stuff for cfn init
  ec2.metadata = ec2_config.to_h

  # associate wait condition/handle and ec2
  cond.set_handle handle
  cond.depends_on = ec2.logical_id

  # add resources and parameter to our template
  template.add_resources [ec2, sg, cond, handle, instance_role, instance_profile, instance_policy, codedeploy_role, codedeploy_policy, rds, vpc, internet_gateway, gateway_attachment, subnet_1, subnet_2, route_table, route, network_acl, inbound_acl, outbound_acl, subnet_acl_association, rds_subnet ]
  template.add_parameters [ssh_key_param, packages_param, github_param, heroku_key_param, heroku_database_user_param, heroku_database_url_param, git_branch_param, heroku_email_param]
  
  return template
end

# print out the template json like so:
puts buster_dev_template.to_json
