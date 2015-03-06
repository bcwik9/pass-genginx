  module Resource
    require 'json'
    
    attr_accessor :name, :type, :properties, :depends_on
    
    ALLOWED_TYPES = ["AWS::EC2::Instance", "AWS::EC2::SecurityGroup", "AWS::CloudFormation::WaitConditionHandle", "AWS::CloudFormation::WaitCondition", "AWS::Route53::RecordSetGroup", "AWS::Route53::HostedZone"]
    
    def initialize opt
      @name = opt[:name] || 'defaultResource'
      raise "Unsupported type: #{opt[:type]}" unless ALLOWED_TYPES.include? opt[:type]
      @type = opt[:type]
      @properties = opt[:properties] || {}
      @depends_on = opt[:depends_on]
    end

    def to_h
      {
        @name => {
          "Type" => @type,
          "Properties" => @properties
        }
      }
    end
    
    def to_json
      to_h.to_json
    end
  end
