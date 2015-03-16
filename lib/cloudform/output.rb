require_relative 'aws_object'

class AwsOutput
  include AwsObject

  attr_accessor :description, :value
  
  def initialize opt={}
    super opt
    @description = opt[:description] || 'Example AWS Output'
    @value = opt[:value] || 'Example output value'
  end
    
  def to_h
    ret = super.to_h
    ret[@logical_id][:Description] = @description
    ret[@logical_id][:Value] = @value
    return ret
  end
end
