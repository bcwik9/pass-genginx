require_relative 'resource'

module AwsElasticBeanstalkResource
  include AwsResource
  
  def initialize opt={}
    super opt
    set_description "AWS Elastic Beanstalk Sample #{self.class.name}"
  end

  def set_description description
    @properties[:Description] = description
  end

  def set_option namespace, option_name, value
    @properties[:OptionSettings] ||= []
    @properties[:OptionSettings] += [
                                     {
                                       :Namespace => namespace,
                                       :OptionName => option_name,
                                       :Value => value
                                     }
                                    ]
  end

end
