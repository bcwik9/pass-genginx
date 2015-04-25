require_relative 'resource'

class AwsIamRole
  include AwsResource

  def initialize opt={}
    opt[:type] = 'AWS::IAM::Role'
    super opt
    set_role_policy_document opt
    set_path opt
  end

  # see https://s3.amazonaws.com/cloudformation-templates-us-east-1/ElastiCache_Redis.template
  def set_role_policy_document opt={}
    opt[:service] ||= ['ec2.amazonaws.com']
    options = {
      :action => opt[:action] || ['sts:AssumeRole'],
      :principal => opt[:princpal] || { :Service => opt[:service] },
      :effect => opt[:effect]
    }

    add_property :AssumeRolePolicyDocument, AwsTemplate.generate_statement(options)
  end

  def set_path opt={}
    path = opt[:path] || '/'
    add_property :path, path
  end
end
