require_relative 'resource'

class AwsElastiCacheSecurityGroup
  include AwsResource
  
  def initialize opt={}
    opt[:type] = "AWS::EC2::SecurityGroup"
    super opt
  end
end
