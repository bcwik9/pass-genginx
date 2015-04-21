require_relative 'aws_object'

class AwsParameter
  include AwsObject

  attr_accessor :description, :type, :allowed_values, :default, :options
  
  ALLOWED_TYPES = ["String", "AWS::EC2::KeyPair::KeyName"]

  def initialize opt={}
    super opt
    @description = opt[:description] || 'Example AWS Parameter'
    @type = opt[:type] || 'String'
    raise "Unsupported type: #{@type}" unless ALLOWED_TYPES.include? @type
    @allowed_values = opt[:allowed_values] || []
    @default = opt[:default]
    @options = opt[:options] || {}
  end

  def add_option key, value
    raise "Must specify valid key and value" if key.nil? or key.empty? or value.nil?
    @options[key] = value
  end
    
  def to_h
    ret = super
    ret[@logical_id][:Description] = @description
    ret[@logical_id][:Type] = @type
    ret[@logical_id][:Default] = @default if @default
    ret[@logical_id][:AllowedValues] = @allowed_values unless @allowed_values.empty?
    # iterate through all options keys and add them
    capitalize_keys(@options).each do |k,v|
      ret[@logical_id][k] = v
    end

    return ret
  end

  private

  # capitalize all keys in a hash if necessary
  def capitalize_keys h
    ret = {}

    h.each do |k,v|
      new_key = k.to_s.split('')
      new_key[0].upcase!
      ret[new_key.join] = v
    end

    return ret
  end
end
