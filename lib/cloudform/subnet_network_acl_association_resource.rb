require_relative 'resource'
require_relative 'output'

class AwsSubnetNetworkAclAssociation
  include AwsResource
  
  attr_accessor :subnet, :network_acl
  
  def initialize opt={}
    opt[:type] = "AWS::EC2::SubnetNetworkAclAssociation"
    super opt
    @subnet = opt[:subnet]
    @network_acl = opt[:network_acl]
  end

  def to_h
    raise 'Must specify an associated subnet' if @subnet.nil?
    raise 'Must specify an associated network acl' if @network_acl.nil?
    add_property :SubnetId, @subnet.get_reference
    add_property :NetworkAclId, @network_acl.get_reference
    super
  end
end
