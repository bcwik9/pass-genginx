require_relative 'resource'

class AwsIamPolicy
  include AwsResource
  
  attr_accessor :name_role, :roles
  
  def initialize opt={}
    opt[:type] = 'AWS::IAM::Policy'
    super opt
    @roles = opt[:roles] || []
    set_policy_name opt[:name_role]
    set_policy_document opt
  end

  def set_policy_name role
    role || raise('Must specify a IAM Role for the policy name!')
    @name_role = role
  end
  
  def add_role role
    @roles.push role.get_reference
  end
  
  def remove_role role
    @roles.delete role.get_reference
  end

  def set_policy_document opt={}
    statement = {
      :action => opt[:action] || 'elasticache:DescribeCacheClusters',
      :resource => opt[:resorce] || '*'
    }
      
    add_property :PolicyDocument, AwsTemplate.generate_statement(statement)
  end

  def to_h
    add_property :Roles, @roles unless @roles.empty?
    add_property :PolicyName, @name_role.logical_id
    super
  end
end
