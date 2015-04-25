require_relative 'resource'

class AwsSecurityGroup
  include AwsResource

  attr_accessor :ports
  
  # SSH (port 22) and HTTP/HTTPS (port 80/443)
  DEFAULT_PORTS = [22,80,443]
  
  def initialize opt={}
    @ports = opt[:ports] || []
    opt[:type] = "AWS::EC2::SecurityGroup"
    super opt
  end

  def generate_description
    ret = 'Enable access to port(s): '
    @ports.each do |port|
      if port[:FromPort] == port[:ToPort]
        ret += "#{port[:FromPort]},"
      else
        ret += "#{port[:FromPort]}-#{port[:ToPort]},"
      end
    end

    return ret
  end

  def update_description
    @properties[:GroupDescription] = generate_description if @properties
  end

  # returns a hash representation of access specification for a security group
  def generate_access opt={}
    sanitize_access opt
    ret = {
      :IpProtocol => opt[:protocol],
      :FromPort => opt[:from],
      :ToPort => opt[:to],
    }
    # check to see if we're using another security group as source
    if opt[:source]
      ret[:SourceSecurityGroupId] = opt[:source]
    else
      ret[:CidrIp] = opt[:ip]
    end
    return ret
  end
  
  # add access to specific port ranges
  def add_access opt={}
    @ports.push generate_access(opt)
    # update the description
    update_description
  end

  # remove access to specific port ranges
  def remove_access opt={}
    @ports.delete generate_access(opt)
    # update the description
    update_description
  end

  # remove all ports
  def clear_access
    @ports.clear
    update_description
  end
  
  # enable access to default ports
  def set_default_properties
    DEFAULT_PORTS.each do |port|
      add_access(:from => port)
    end
    
    @properties = {
      :GroupDescription => generate_description,
      :SecurityGroupIngress => @ports
    }
  end

  private

  # ensures that all necessary params are present when specifying access
  def sanitize_access opt={}
    raise "Must specify an option hash" unless opt.class == Hash
    raise "Must specify a port" unless opt[:from]
    opt[:to] = opt[:from] unless opt[:to]
    opt[:protocol] = 'tcp' unless opt[:protocol]
    opt[:ip] = '0.0.0.0/0' unless opt[:ip]
  end

end
