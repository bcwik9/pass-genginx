require_relative 'resource'

class AwsWaitCondition
  include AwsResource

  def initialize opt={}
    opt[:type] = 'AWS::CloudFormation::WaitCondition'
    super opt
    set_timeout (opt[:timeout] || 600)
  end

  def set_handle handle
    @properties[:Handle] = handle.get_reference
  end

  def set_timeout timeout
    @properties[:Timeout] = timeout
  end
end
