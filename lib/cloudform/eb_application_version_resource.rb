require_relative 'eb_resource'

class AwsElasticBeanstalkApplicationVersion
  include AwsElasticBeanstalkResource
  
  
  def initialize opt={}
    opt[:type] = "AWS::ElasticBeanstalk::ApplicationVersion"
    super opt
  end
  
  def set_application_name name
    @properties[:ApplicationName] = name
  end

  # where we'll retrieve the application code
  def set_source bucket, key
    @properties[:SourceBundle] = {
      :S3Bucket => bucket,
      :S3Key => key
    }
  end

end
