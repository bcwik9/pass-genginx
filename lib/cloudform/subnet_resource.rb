require_relative 'resource'
require_relative 'output'

class AwsSubnet
  include AwsResource
  
  attr_accessor :cidr_block, :vpc
  
  def initialize opt={}
    opt[:type] = "AWS::EC2::Subnet"
    super opt
    @cidr_block = opt[:cidr_block] || '10.0.0.0/24'
    @vpc = opt[:vpc]
    add_property :AvailabilityZone, opt[:availability_zone] if opt[:availability_zone]
    add_property :MapPublicIpOnLaunch, (opt[:assign_public_ips] || true)
  end

  def set_vpc vpc
    @vpc = vpc
  end

  def to_h
    add_property :CidrBlock, @cidr_block
    add_property :VpcId, @vpc.get_reference
    super
  end
end
