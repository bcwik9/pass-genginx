require_relative 'resource'
require_relative 'output'

class AwsRdsDbSubnetGroup
  include AwsResource
  
  attr_accessor :description, :subnets
  
  def initialize opt={}
    opt[:type] = "AWS::RDS::DBSubnetGroup"
    super opt
    @description = opt[:description] || "Default RDS DB Subnet Group"
    @subnets = opt[:subnets] || clear_subnets
  end

  def add_subnet subnet
    @subnets.push subnet
  end

  def clear_subnets
    @subnets = []
  end

  def to_h
    raise 'Must specify at least one subnet' if @subnets.nil? or @subnets.empty?
    add_property :DBSubnetGroupDescription, @description
    add_property :SubnetIds, @subnets.map { |subnet| subnet.get_reference }
    super
  end
end
