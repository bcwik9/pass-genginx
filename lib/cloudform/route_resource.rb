require_relative 'resource'
require_relative 'output'

class AwsRoute
  include AwsResource
  
  attr_accessor :destination_cidr_block, :route_table
  
  def initialize opt={}
    opt[:type] = "AWS::EC2::Route"
    super opt
    @destination_cidr_block = opt[:destination_cidr_block] || '0.0.0.0/0'
    @route_table = opt[:route_table]
  end

  def add_gateway gateway
    add_property :GatewayId, gateway.get_reference
  end

  def to_h
    raise 'Must specify a route table' if @route_table.nil? or @route_table.empty?
    add_proprty :RouteTableId, @route_table.get_reference
    add_property :DestinationCidrBlock, @destination_cidr_block
    super
  end
  
end
