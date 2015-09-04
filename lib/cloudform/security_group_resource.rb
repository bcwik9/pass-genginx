require_relative 'security_group_access'

class AwsSecurityGroup
  include AwsResource

  attr_accessor :inbound_ports, :outbound_ports
  
  # SSH (port 22) and HTTP/HTTPS (port 80/443)
  DEFAULT_INBOUND_PORTS = [22,80,443]
  
  def initialize opt={}
    @inbound_ports = opt[:inbound_ports] || []
    @outbound_ports = opt[:outbound_ports] || []
    opt[:type] = "AWS::EC2::SecurityGroup"
    super opt
  end

  def generate_description
    ret = 'Enable access to port(s): '
    @inbound_ports.each do |port|
      if port[:FromPort] == port[:ToPort]
        ret += "#{port[:FromPort]},"
      else
        ret += "#{port[:FromPort]}-#{port[:ToPort]},"
      end
    end

    return ret
  end

  def associate_vpc vpc
    add_property :VpcId, vpc.get_reference
  end

  # returns a hash representation of access specification for a security group
  def generate_access opt={}
    opt[:security_group] = self
    raise 'Use AwsSecurityGroupAccess to allow a security group to communicate with itself' if  self == opt[:source]
    new_access = AwsSecurityGroupAccess.generate_inbound_access(opt)
    new_access.to_h
    new_access.properties.delete(:GroupId)
    return new_access.properties
  end
  
  # add access to specific port ranges
  def add_inbound_access opt={}
    @inbound_ports.push generate_access(opt)
  end

  # remove access to specific port ranges
  def remove_inbound_access opt={}
    @inbound_ports.delete generate_access(opt)
  end

  # remove all inbound ports
  def clear_inbound_access
    @inbound_ports.clear
  end

  # add access to specific port ranges
  def add_outbound_access opt={}
    @outbound_ports.push generate_access(opt)
  end

  # remove access to specific port ranges
  def remove_outbound_access opt={}
    @outbound_ports.delete generate_access(opt)
  end

  # remove all outbound ports
  def clear_outbound_access
    @outbound_ports.clear
  end
  
  # enable access to default inbound ports
  def set_default_properties
    DEFAULT_INBOUND_PORTS.each do |port|
      add_inbound_access(:from => port)
    end
    super
  end

  def to_h
    add_property :GroupDescription, generate_description
    add_property :SecurityGroupIngress, @inbound_ports unless @inbound_ports.empty?
    add_property :SecurityGroupEgress, @outbound_ports unless @outbound_ports.empty?
    super
  end

end
