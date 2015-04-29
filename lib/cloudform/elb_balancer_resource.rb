require_relative 'resource'

class AwsElasticLoadBalancer
  include AwsResource

  attr_reader :instances
  
  def initialize opt={}
    opt[:type] = 'AWS::ElasticLoadBalancing::LoadBalancer'
    super opt
    @instances = []
  end

  def set_default_properties
    @properties = {
      :AvailabilityZones => AwsTemplate.availability_zones,
    }
  end

  def add_instance instance
    @instances.push instance
  end

  def self.generate_listener opt={}
    raise 'Must specify load balancer port' unless opt[:port]
    opt[:instance_port] ||= opt[:port]
    opt[:protocol] ||= 'HTTP'
    {
      :LoadBalancerPort => opt[:port],
      :InstancePort => opt[:instance_port],
      :Protocol => opt[:protocol]
    }
  end

  def add_listener opt={}
    @properties[:Listeners] ||= []
    @properties[:Listeners].push AwsElasticLoadBalancer.generate_listener(opt)
  end

  def self.generate_health_check opt={}
    raise 'Must specify target' unless opt[:target]
    {
      :Target => opt[:target],
      :HealthyThreshold => (opt[:healthy_threshold] || 3),
      :UnhealthyThreshold => (opt[:uhnealthy_threshold] || 5),
      :Interval => (opt[:interval] || 30),
      :Timeout => (opt[:timeout] || 5)
    }
  end

  def add_health_check opt={}
    @properties[:HealthCheck] = AwsElasticLoadBalancer.generate_health_check(opt)
  end

  def to_h
    unless @instances.empty?
      @properties[:Instances] = []
      @instances.each do |instance|
        @properties[:Instances].push instance.get_reference
      end
    end

    super
  end
end
