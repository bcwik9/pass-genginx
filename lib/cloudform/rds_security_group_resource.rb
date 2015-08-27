require_relative 'resource'

class AwsRdsSecurityGroup
  include AwsResource

  attr_accessor :description, :ingress
  
  def initialize opt={}
    opt[:type] = "AWS::RDS::DBSecurityGroup"
    super opt
    @description = opt[:description] || 'Default DB Security Group for RDS'
    @ingress = opt[:ingress] || raise('Must specify DBSecurityGroupIngress')
  end

  def to_h
    add_property :GroupDescription, @description
    add_property :DBSecurityGroupIngress, @ingress
    super
  end

end
