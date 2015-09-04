require_relative 'resource'
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

  # returns a hash representation of access specification for a security group
  def generate_access opt={}
    opt[:security_group] = self
    ret = AwsSecurityGroupAccess.generate_inbound_access(opt).properties
    ret.delete :GroupId #isn't used
    return ret

    sanitize_access opt
    ret = {
      :IpProtocol => opt[:protocol],
      :FromPort => opt[:from],
      :ToPort => opt[:to],
    }
    # check to see if we're using another security group as source
    if opt[:source_security_group]
      raise 'Use AwsSecurityGroupAccess to allow a security group to communicate with itself' if @logical_id == opt[:source_security_group].logical_id
      ret[:SourceSecurityGroupId] = opt[:source_security_group]
    elsif opt[:destination_security_group]
      ret[:DestinationSecurityGroupId] = opt[:destination_security_group]
    else
      ret[:CidrIp] = opt[:ip]
    end
    return ret
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
