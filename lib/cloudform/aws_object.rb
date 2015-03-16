require_relative 'template'

module AwsObject
  attr_accessor :logical_id

  def initialize opt
    @logical_id = opt[:logical_id] || set_default_logical_id  
  end
  
  def set_default_logical_id
    @logical_id = "default#{self.class.to_s}"
  end
  
  def get_att attribute
    {
      "Fn::GetAtt" => [ @logical_id, attribute ]
    } 
  end

  def get_reference
    {
      :Ref => @logical_id
    }
  end
  
  def to_h
    {
      @logical_id => {}
    }
  end
  
  def to_json
    to_h.to_json
  end
end
