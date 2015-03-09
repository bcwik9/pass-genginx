require_relative 'template'
require_relative 'output'

module AwsResource  
  require 'json'

  attr_accessor :name, :type, :properties, :depends_on
  
  ALLOWED_TYPES = ["AWS::EC2::Instance", "AWS::EC2::SecurityGroup", "AWS::CloudFormation::WaitConditionHandle", "AWS::CloudFormation::WaitCondition", "AWS::Route53::RecordSetGroup", "AWS::Route53::HostedZone"]
  
  def initialize opt
    @name = opt[:name] || set_default_name
    raise "Unsupported type: #{opt[:type]}" unless ALLOWED_TYPES.include? opt[:type]
    @type = opt[:type]
    @properties = opt[:properties] || set_default_properties
    @depends_on = opt[:depends_on]
  end

  def get_reference
    {
      :Ref => @name
    }
  end
  
  def generate_outputs
    [
     AwsOutput.new
    ]
  end

  def set_default_properties
    @properties = {}
  end

  def set_default_name
    @name = 'defaultResource'
  end

  def get_att attribute
    {
      "Fn::GetAtt" => [ @name, attribute ]
    } 
  end

  def to_h
    ret = {
      @name => {
        :Type => @type,
        :Properties => @properties
      }
    }
    ret[@name][:DependsOn] = @depends_on if @depends_on
    return ret
  end

  def to_json
    to_h.to_json
  end
end
