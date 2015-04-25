require_relative 'resource'

class AwsElastiCacheSecurityGroupIngress
  include AwsResource

  attr_accessor :cache_security_group, :ec2_security_group

  def initialize opt={}
    opt[:type] = "AWS::ElastiCache::SecurityGroupIngress"
    super opt
    @cache_security_group = opt[:cache_security_group] || raise("Must specify cache security group name")
    @ec2_security_group = opt[:ec2_security_group] || raise("Must specify ec2 security group name")
  end
  
  def to_h
    add_property :CacheSecurityGroupName, @cache_security_group.get_reference
    add_property :EC2SecurityGroupName, @ec2_security_group.get_reference
    super
  end
end
