require_relative 'resource'

class AwsAutoScalingPolicy
  include AwsResource

  def initialize opt={}
    opt[:type] = 'AWS::AutoScaling::ScalingPolicy'
    super opt
    set_adjustment_type opt[:adjustment_type]
    set_scaling_group opt[:group]
    set_cooldown opt[:cooldown]
    set_scaling_adjustment opt[:adjustment]
  end

  def set_adjustment_type type
    type ||= 'ChangeInCapacity'
    add_property :AdjustmentType, type
  end

  def set_scaling_group group
    raise 'Must specify auto scaling group name' if group.nil?
    add_property :AutoScalingGroupName, group.get_reference
  end

  def set_cooldown cooldown
    cooldown ||= 1
    add_property :Cooldown, cooldown
  end

  def set_scaling_adjustment adjustment
    adjustment ||= 1
    add_property :ScalingAdjustment, adjustment
  end
end
