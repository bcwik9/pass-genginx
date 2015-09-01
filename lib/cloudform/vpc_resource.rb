require_relative 'resource'
require_relative 'output'

class AwsVpc
  include AwsResource
  
  attr_accessor :cidr_block
  
  def initialize opt={}
    opt[:type] = "AWS::EC2::VPC"
    super opt
    @cidr_block = opt[:cidr_block] || '10.0.0.0/16'
    set_dns_support (opt[:dns_support] || true)
    set_dns_hostnames (opt[:dns_hostnames] || true)
  end

  def set_dns_support val
    add_property :EnableDnsSupport, val
  end

  def set_dns_hostnames val
    add_property :EnableDnsHostnames, val
  end


  def to_h
    add_property :CidrBlock, @cidr_block
    super
  end
end
