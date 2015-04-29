require_relative 'aws_object'

module AwsResource
  include AwsObject
  
  attr_accessor :type, :properties, :depends_on
  
  ALLOWED_TYPES = ["AWS::EC2::Instance", "AWS::EC2::SecurityGroup", "AWS::CloudFormation::WaitConditionHandle", "AWS::CloudFormation::WaitCondition", "AWS::Route53::RecordSetGroup", "AWS::Route53::HostedZone", "AWS::ElasticBeanstalk::Application", "AWS::ElasticBeanstalk::ApplicationVersion", "AWS::ElasticBeanstalk::ConfigurationTemplate", "AWS::ElasticBeanstalk::Environment", "AWS::ElastiCache::CacheCluster", "AWS::ElastiCache::ParameterGroup", "AWS::ElastiCache::SecurityGroupIngress", "AWS::ElastiCache::SecurityGroup", "AWS::IAM::Policy", "AWS::IAM::Role", 'AWS::IAM::InstanceProfile', 'AWS::AutoScaling::ScalingPolicy', 'AWS::CloudWatch::Alarm', 'AWS::AutoScaling::AutoScalingGroup', 'AWS::ElasticLoadBalancing::LoadBalancer']
  
  def initialize opt
    raise "Unsupported type: #{opt[:type]}" unless ALLOWED_TYPES.include? opt[:type]
    super opt
    @type = opt[:type]
    @properties = opt[:properties] || set_default_properties
    @depends_on = opt[:depends_on]
  end

  def set_default_properties
    @properties = {}
  end

  def add_property key, value
    raise "Must specify valid key and value" if key.nil? or key.empty? or value.nil?
    new_key = AwsTemplate.capitalize_symbol key
    @properties[new_key] = value
  end

  def to_h
    ret = super
    ret[@logical_id][:Type] = @type
    ret[@logical_id][:Properties] = @properties
    ret[@logical_id][:DependsOn] = @depends_on if @depends_on
    return ret
  end
end
