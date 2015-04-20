require_relative 'eb_resource'

class AwsElasticBeanstalkEnvironment
  include AwsElasticBeanstalkResource
  
  
  def initialize opt={}
    opt[:type] = "AWS::ElasticBeanstalk::Environment"
    super opt
  end

  def set_application_name name
    @properties[:ApplicationName] = name
  end

  def set_template_name name
    @properties[:TemplateName] = name
  end

  def set_version_label label
    @properties[:VersionLabel] = label
  end
end
