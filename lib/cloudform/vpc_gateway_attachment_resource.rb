require_relative 'resource'
require_relative 'output'

class AwsVpcGatewayAttachment
  include AwsResource
  
  attr_accessor :vpc, :gateway
  
  def initialize opt={}
    opt[:type] = "AWS::EC2::VPCGatewayAttachment"
    super opt
    @vpc = opt[:vpc]
    @gateway = opt[:gateway]
  end

  def to_h
    raise 'Must specify an associated VPC' if @vpc.nil?
    raise 'Must specify an associated gateway' if @gateway.nil?
    add_property :VpcId, @vpc.get_reference
    if @gateway.type == 'AWS::EC2::VPNGateway'
      add_property :VpnGatewayId, @gateway.get_reference
    else
      add_property :InternetGatewayId, @gateway.get_reference
    end

    super
  end
  
end
