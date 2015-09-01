require_relative 'resource'
require_relative 'output'

class AwsRouteTable
  include AwsResource
  
  attr_accessor :vpc
  
  def initialize opt={}
    opt[:type] = "AWS::EC2::RouteTable"
    super opt
    @vpc = opt[:vpc]
  end

  def set_vpc vpc
    @vpc = vpc
  end

  def to_h
    raise 'Must specify an associated VPC' if @vpc.nil or @vpc.empty?
    add_property :VpcId, @vpc.get_reference
    super
  end
  
end
