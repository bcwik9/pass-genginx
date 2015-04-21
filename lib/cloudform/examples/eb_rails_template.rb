require_relative '../template'
require_relative '../parameter'
require_relative '../eb_application_resource'
require_relative '../eb_application_version_resource'
require_relative '../eb_config_template_resource'
require_relative '../eb_environment_resource'


# json to create an elastic beanstalk Rails application from a project zip stored in S3
def eb_app_call
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
  eb_version.set_source bucket_name_param.get_reference, project_zip_param.get_reference

  eb_config = AwsElasticBeanstalkConfigurationTemplate.new
  eb_config.set_application_name eb_app.get_reference
  eb_config.enable_single_instance
  eb_config.set_instance_type 't2.micro'
  eb_config.set_stack_name "64bit Amazon Linux 2015.03 v1.3.0 running Ruby 2.2 (Passenger Standalone)"
  eb_config.set_option "aws:elasticbeanstalk:application:environment", "SECRET_KEY_BASE", secret_key_param.get_reference

  eb_env = AwsElasticBeanstalkEnvironment.new
  eb_env.set_application_name eb_app.get_reference
  eb_env.set_template_name eb_config.get_reference
  eb_env.set_version_label eb_version.get_reference
  
  # create a blank template and add all the resources/parameters we need
  template = AwsTemplate.new
  template.add_resources [eb_app, eb_version, eb_config, eb_env]
  template.add_parameters [secret_key_param, bucket_name_param, project_zip_param]

  return template.to_json
end

puts eb_app_call
