require_relative 'resource'

class AwsRdsSecurityGroup
  include AwsResource

  attr_accessor :description, :ingress
  
  def initialize opt={}
    opt[:type] = "AWS::RDS::DBSecurityGroup"
    super opt
    @description = opt[:description] || 'Default DB Security Group for RDS'
    @ingress = opt[:ingress] || []
    opt[:ec2_security_groups].each do |security_group|
      associate_ec2_security_group security_group
    end
  end

  def associate_ec2_security_group ec2_security_group
    @ingress.push ({
      EC2SecurityGroupName: ec2_security_group.get_reference
    })
  end

  def clear_associated_security_groups
    @ingress.clear
  end

  def to_h
    raise 'Must specify DBSecurityGroupIngress' if @ingress.nil? or @ingress.empty?
    add_property :DBSecurityGroupIngress, @ingress
    add_property :GroupDescription, @description
    super
  end

end
