require_relative 'resource'

class AwsCloudWatchAlarm
  include AwsResource

  attr_reader :dimensions, :actions

  def initialize opt={}
    opt[:type] = 'AWS::CloudWatch::Alarm'
    super opt
    clear_dimensions
    clear_alarm_actions
    set_evaluation_periods opt[:periods]
    set_statistic opt[:statistic]
    set_threshold opt[:threshold]
    set_description opt[:description]
    set_period opt[:period]
    set_namespace opt[:namespace]
    set_comparison_operator opt[:operator]
    set_metric_name opt[:metric]
  end

  def set_evaluation_periods periods
    periods ||= 1
    add_property :EvaluationPeriods, 1
  end

  def set_statistic stat
    stat ||= 'Average'
    add_property :Statistic, stat
  end

  def set_threshold threshold
    threshold ||= 10
    add_property :Threshold, threshold
  end
  
  def set_description description
    description ||= 'Example CloudWatch Alarm'
    add_property :AlarmDescription, description
  end

  def set_period period
    period ||= 60
    add_property :Period, period
  end

  def add_alarm_action action
    @actions.push action
  end

  def clear_alarm_actions
     @actions = []
  end

  def set_namespace namespace
    namespace ||= 'AWS/EC2'
    add_property :Namespace, namespace
  end

  def add_dimension name, value
    @dimensions.push({:Name => name, :Value => value})
  end

  def clear_dimensions
    @dimensions = []
  end

  def set_comparison_operator operator
    operator ||= 'GreaterThanThreshold'
    add_property :ComparisonOperator, operator
  end

  def set_metric_name name
    name ||= 'CPUUtilization'
    add_property :MetricName, name
  end

  def to_h
    actions = []
    @actions.each do |action|
      actions.push action.get_reference
    end
    add_property :AlarmActions, actions unless actions.empty?
    add_property :Dimensions, @dimensions unless @dimensions.empty?    

    super
  end
  
end
