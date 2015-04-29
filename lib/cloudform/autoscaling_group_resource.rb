require_relative 'resource'

class AwsAutoScalingGroup
  include AwsResource

  attr_reader :load_balancers

  def initialize opt={}
    opt[:type] = 'AWS::AutoScaling::AutoScalingGroup'
    super opt
    
    set_min_size opt[:min]
    set_max_size opt[:max]
    set_availability_zones opt[:zones]
    clear_load_balancers
    raise 'Must specify at least one load balancer' if opt[:load_balancers].nil? or opt[:load_balancers].empty?
    opt[:load_balancers].each do |lb|
      add_load_balancer lb
    end
    set_launch_configuration opt[:launch_config]
  end

  def set_launch_configuration config
    raise 'Must specify launch configuration' if config.nil?
    add_property :LaunchConfigurationName, config.get_reference
  end

  def set_min_size size
    size ||= 1
    add_property :MinSize, size
  end

  def set_max_size size
    size ||= 1
    add_property :MaxSize, size
  end

  def set_availability_zones zones
    # by default, specify all availability zones for the region in which the stack is created
    zones ||= AwsTemplate.availability_zones
    add_property :AvailabilityZones, zones
  end

  def add_load_balancer lb
    raise 'Must specify load balancer' if lb.nil?
    @load_balancers.push lb
  end

  def clear_load_balancers
    @load_balancers = []
  end

  def to_h
    load_balancers = []
    @load_balancers.each do |lb|
      load_balancers.push lb.get_reference
    end
    add_property :LoadBalancerNames, load_balancers

    super
  end
end
