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
  iam_policy = AwsIamPolicy.new(:name_role => iam_role)
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

  template = AwsTemplate.new(:description => 'Create a single EC2 instance with a bitnami image to demonstrate the use of cfn-init. Install a sample github project and make it available on port 80, normal HTTP traffic')
  template.add_resources [ec2, ec2_sg]
  template.add_parameter ssh_key_param
  return template
end

# print out the template json like so:
puts ec2_with_elasticache_template.to_json
