require_relative 'resource'

class AwsSecurityGroup
  include AwsResource

  attr_accessor :ports
  
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
  
  def add_access  from, to=from, protocol='tcp', ip='0.0.0.0/0'
    @ports.push({
                  :IpProtocol => protocol,
                  :FromPort => from,
                  :ToPort => to,
                  :CidrIp => ip
                })
  end
  
  # enable access to SSH (port 22) and HTTP/HTTPS (port 80/443)
  def set_default_properties
    [22,80,443].each do |port|
      add_access port
    end
    
    @properties = {
      :GroupDescription => generate_description,
      :SecurityGroupIngress => @ports,
      :Tags => [
                {
                  :Key => 'Name',
                  :Value => @name
                },
                {
                  :Key => 'deployer',
                  :Value => 'ubuntu'
                }
               ]
    }
  end
end
