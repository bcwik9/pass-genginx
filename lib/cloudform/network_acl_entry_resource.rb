require_relative 'resource'
require_relative 'output'

class AwsNetworkAclEntry
  include AwsResource
  
  attr_accessor :cidr_block, :outbound_traffic, :network_acl, :protocol, :rule_action, :rule_number
  
  def initialize opt={}
    opt[:type] = "AWS::EC2::NetworkAclEntry"
    super opt
    @cidr_block = opt[:cidr_block] || '0.0.0.0/0'
    @outbound_traffic = opt[:outbound_traffic].nil? ? true : opt[:outbound_traffic]
    @network_acl = opt[:network_acl]
    @protocol = opt[:protocol] || -1 # -1 is all ports
    @rule_action = opt[:rule_action] || 'allow'
    @rule_number = opt[:rule_number] || 100
  end

  # sets a port range. default protocol of 6 for TCP
  # see http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml for more port protocol numbers, or set to -1 for all ports
  def set_port_range from, to=from, protocol=6
    @protocol = protocol
    add_property :PortRange, { :From => from, :To => to }
  end

  def to_h
    add_property :CidrBlock, @cidr_block
    add_property :NetworkAclId, @network_acl.get_reference
    add_property :RuleNumber, @rule_number
    add_property :RuleAction, @rule_action
    add_property :Protocol, @protocol
    add_property :Egress, @outbound_traffic
    super
  end
end
