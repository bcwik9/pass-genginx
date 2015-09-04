require_relative 'aws_object'

module AwsResource
  include AwsObject
  
  attr_accessor :type, :properties, :depends_on
  
  ALLOWED_TYPES = ["AWS::EC2::Instance", "AWS::EC2::SecurityGroup", "AWS::CloudFormation::WaitConditionHandle", "AWS::CloudFormation::WaitCondition", "AWS::Route53::RecordSetGroup", "AWS::Route53::HostedZone", "AWS::ElasticBeanstalk::Application", "AWS::ElasticBeanstalk::ApplicationVersion", "AWS::ElasticBeanstalk::ConfigurationTemplate", "AWS::ElasticBeanstalk::Environment", "AWS::ElastiCache::CacheCluster", "AWS::ElastiCache::ParameterGroup", "AWS::ElastiCache::SecurityGroupIngress", "AWS::ElastiCache::SecurityGroup", "AWS::IAM::Policy", "AWS::IAM::Role", 'AWS::IAM::InstanceProfile', 'AWS::AutoScaling::ScalingPolicy', 'AWS::CloudWatch::Alarm', 'AWS::AutoScaling::AutoScalingGroup', 'AWS::ElasticLoadBalancing::LoadBalancer', 'AWS::RDS::DBInstance', 'AWS::RDS::DBSecurityGroup', 'AWS::EC2::VPC', 'AWS::EC2::Subnet', 'AWS::EC2::RouteTable', 'AWS::EC2::InternetGateway', "AWS::EC2::VPCGatewayAttachment", "AWS::EC2::SubnetNetworkAclAssociation", "AWS::EC2::NetworkAcl", "AWS::EC2::NetworkAclEntry", "AWS::RDS::DBSubnetGroup", "AWS::EC2::SubnetRouteTableAssociation", "AWS::EC2::Route", "AWS::EC2::SecurityGroupIngress", "AWS::EC2::SecurityGroupEgress" ]
  
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
    @properties[AwsTemplate.capitalize_symbol key] = value
  end

  def get_property key
    raise "Must specify key" if key.nil? or key.empty?
    @properties[AwsTemplate.capitalize_symbol key]
  end

  def to_h
    ret = super
    ret[@logical_id][:Type] = @type
    ret[@logical_id][:Properties] = @properties
    ret[@logical_id][:DependsOn] = @depends_on if @depends_on
    return ret
  end
end
