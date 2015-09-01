require_relative 'resource'
require_relative 'output'

class AwsNetworkAcl
  include AwsResource
  
  attr_accessor :vpc
  
  def initialize opt={}
    opt[:type] = "AWS::EC2::NetworkAcl"
    super opt
    @vpc = opt[:vpc]
  end

  def to_h
    raise 'Must specify an associated VPC' if @vpc.nil or @vpc.empty?
    add_property :VpcId, @vpc.get_reference
    super
  end
end
