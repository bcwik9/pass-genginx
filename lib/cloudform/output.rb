require_relative 'template'

class AwsOutput
  attr_accessor :name, :description, :value
  
  def initialize opt={}
    @name = opt[:name] || 'defaultOutput'
    @description = opt[:description] || 'Example AWS Output'
    @value = opt[:value] || ''
  end
    
  def to_h
    {
      @name => {
        :Description => @description,
        :Value => @value
      }
    }
  end

  def to_json
    to_h.to_json
  end
end
