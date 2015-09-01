require_relative 'resource'
require_relative 'output'

class AwsInternetGateway
  include AwsResource
  
  def initialize opt={}
    opt[:type] = "AWS::EC2::InternetGateway"
    super opt
  end
end
