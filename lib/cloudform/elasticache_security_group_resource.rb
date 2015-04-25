require_relative 'resource'

class AwsElastiCacheSecurityGroup
  include AwsResource

  def initialize opt={}
    opt[:type] = "AWS::ElastiCache::SecurityGroup"
    super opt
    add_property :Description, "Example ElastiCache Security Group"
  end
  
end
