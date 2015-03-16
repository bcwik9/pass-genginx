require_relative 'aws_object'

class AwsParameter
  include AwsObject

  attr_accessor :description, :type, :allowed_values, :default, :other
  
  ALLOWED_TYPES = ["String", "AWS::EC2::KeyPair::KeyName"]

  def initialize opt={}
    super opt
    @description = opt[:description] || 'Example AWS Parameter'
    @type = opt[:type] || 'String'
    raise "Unsupported type: #{@type}" unless ALLOWED_TYPES.include? @type
    @allowed_values = opt[:allowed_values] || []
    @default = opt[:default]
    @other = opt[:other] || {}
  end
    
  def to_h
    ret = super.to_h
    ret[@logical_id][:Description] = @description
    ret[@logical_id][:Type] = @type
    ret[@logical_id][:Default] if @default
    ret[@logical_id][:AllowedValues] = @allowed_values unless @allowed_values.empty?
    # iterate through all other keys and add them
    @other.each do |k,v|
      ret[@logical_id][k] = v
    end

    return ret
  end
end
