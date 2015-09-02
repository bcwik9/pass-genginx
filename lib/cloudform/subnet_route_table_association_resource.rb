require_relative 'resource'
require_relative 'output'

class AwsSubnetRouteTableAssociation
  include AwsResource
  
  attr_accessor :subnet, :route_table
  
  def initialize opt={}
    opt[:type] = "AWS::EC2::SubnetRouteTableAssociation"
    super opt
    @subnet = opt[:subnet]
    @route_table = opt[:route_table]
  end

  def to_h
    raise 'Must specify an associated subnet' if @subnet.nil?
    raise 'Must specify an associated route table' if @route_table.nil?
    add_property :SubnetId, @subnet.get_reference
    add_property :RouteTableId, @route_table.get_reference
    super
  end
end
