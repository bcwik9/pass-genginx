require_relative 'resource'

class AwsWaitHandle
  include AwsResource

  def initialize opt={}
    opt[:type] = 'AWS::CloudFormation::WaitConditionHandle'
    super opt
  end
end
