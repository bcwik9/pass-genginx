require_relative 'eb_resource'

class AwsElasticBeanstalkConfigurationTemplate
  include AwsElasticBeanstalkResource
  
  
  def initialize opt={}
    opt[:type] = "AWS::ElasticBeanstalk::ConfigurationTemplate"
    super opt
  end

  def set_default_properties
    super
    set_stack_name 'DefaultStackName'
  end

  def set_application_name name
    @properties[:ApplicationName] = name
  end

  def set_stack_name name
    @properties[:SolutionStackName] = name
  end
  
  # if we want our environment to be load balanced
  def enable_load_balancing min=2, max=min
    max = min if max < min
    set_option "aws:autoscaling:asg", "MinSize", min
    set_option "aws:autoscaling:asg", "MaxSize", max
    set_option "aws:elasticbeanstalk:environment", "EnvironmentType", "LoadBalanced"
  end

  # if we don't need to load balance
  def enable_single_instance
    set_option "aws:elasticbeanstalk:environment", "EnvironmentType", "SingleInstance"
  end
  
  # if we want to have ssh access
  def enable_ssh_access key_ref
    set_option "aws:autoscaling:launchconfiguration", "EC2KeyName", key_ref
  end

  # override the default Amazon Machine Image (AMI) by specifying your own custom AMI ID
  def set_image_id id
    set_option "aws:autoscaling:launchconfiguration", "ImageId", id
  end

  def set_instance_type type
    set_option "aws:autoscaling:launchconfiguration", "InstanceType", type
  end

end
