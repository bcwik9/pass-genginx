require_relative 'resource'

class AwsSecurityGroupAccess
  include AwsResource

  attr_accessor :from, :to, :protocol, :security_group, :source

  def self.generate_inbound_access opt={}
    opt[:type] = "AWS::EC2::SecurityGroupIngress"
    AwsSecurityGroupAccess.new opt
  end

  def self.generate_outbound_access opt={}
    opt[:type] = "AWS::EC2::SecurityGroupEgress"
    AwsSecurityGroupAccess.new opt
  end

  def to_h
    raise 'Must specify port to allow access to' if @from.nil? or @to.nil?
    raise 'Must specify security group to modify' if @security_group.nil?
    add_property :FromPort, @from
    add_property :ToPort, @to
    add_property :GroupId, @security_group.get_reference
    add_property :IpProtocol, @protocol
    set_source
    super
  end

  private

  def initialize opt={}
    super opt
    sanitize_access opt
    @from = opt[:from]
    @to = opt[:to] || @from
    @protocol = opt[:protocol] || 'tcp'
    @security_group = opt[:security_group]
    @source = opt[:source]
  end

  def set_source
    @source ||= '0.0.0.0\0'
    if @source.class == String.class
      add_property :CidrIp, @source
    elsif @type == "AWS::EC2::SecurityGroupIngress"
      add_property :SourceSecurityGroupId, @source.get_reference
    else
      add_property :DestinationSecurityGroupId, @source.get_reference
    end
  end

  # ensures that all necessary params are present when specifying access
  def sanitize_access opt={}
    raise "Must specify a port" unless opt[:from]
    opt[:to] = opt[:from] unless opt[:to]
    opt[:protocol] = 'tcp' unless opt[:protocol]
  end
  
end
