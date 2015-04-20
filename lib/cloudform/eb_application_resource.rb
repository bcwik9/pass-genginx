require_relative 'eb_resource'

class AwsElasticBeanstalkApplication
  include AwsElasticBeanstalkResource
  
  
  def initialize opt={}
    opt[:type] = "AWS::ElasticBeanstalk::Application"
    super opt
  end
end
