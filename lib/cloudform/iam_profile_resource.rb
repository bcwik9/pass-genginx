require_relative 'resource'

class AwsIamInstanceProfile
  include AwsResource
  
  attr_accessor :roles
  
  def initialize opt={}
    opt[:type] = 'AWS::IAM::InstanceProfile'
    @roles = opt[:roles] || []
    super opt
    set_path opt
  end
  
  def add_role role
    @roles.push role.get_reference
  end
  
  def remove_role role
    @roles.delete role.get_reference
  end

  def set_path opt={}
    path = opt[:path] || '/'
    add_property :path, path
  end

  def to_h
    add_property :Roles, @roles unless @roles.empty?
    super
  end
end
