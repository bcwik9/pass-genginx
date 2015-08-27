require_relative 'resource'
require_relative 'output'

class AwsElastiCacheCluster
  include AwsResource
  
  attr_accessor :node_type, :engine, :num_nodes

  VALID_ENGINES = %w[ redis memcached ]
  
  def initialize opt={}
    opt[:type] = "AWS::ElastiCache::CacheCluster"
    super opt
    @node_type = opt[:node_type] || 'cache.t2.micro'
    @engine = opt[:engine] || 'redis'
    raise "Invalid engine specified" unless VALID_ENGINES.include? @engine
    @num_nodes = opt[:num_nodes] || 1
  end

  def set_single_az_mode
    add_property :AZMode, 'single-az'
    @properties.delete(:PreferredAvailabilityZones)
  end
  
  # sets cross-az mode, adds preferred zones, and updates number of nodes
  def add_zones zones
    raise "WARNING: cloudformation doesn't currently support multi-zone Redis ElastiCache!" if @engine =~ /redis/i
    raise "Must specify list of preferred zones" if zones.nil? or zones.empty?

    # set AZ mode
    add_property :AZMode, 'cross-az'
    
    # make sure we don't overwrite existing zones
    if @properties[:PreferredAvailabilityZones].nil? or @properties[:PreferredAvailabilityZones].empty?
      @properties[:PreferredAvailabilityZones] = []
    end

    # add zones to list
    @properties[:PreferredAvailabilityZones] += zones
    
    # set correct number of nodes
    @num_nodes = @properties[:PreferredAvailabilityZones].size
  end

  def generate_outputs
    return [] if @engine =~ /redis/i
    [
     AwsOutput.new(:logical_id => "#{@logical_id}Address", :description => "Address for ElastiCache Cluster #{@logical_id}", :value => get_att('ConfigurationEndpoint.Address')),
     AwsOutput.new(:logical_id => "#{@logical_id}Port", :description => "Port for ElastiCache Cluster #{@logical_id}", :value => get_att('ConfigurationEndpoint.Port'))
    ]
  end

  def to_h
    raise "WARNING: cloudformation currently only supports 1 redis node!" if @engine =~ /redis/i and @num_nodes != 1
    add_property :CacheNodeType, @node_type
    add_property :Engine, @engine
    add_property :NumCacheNodes, @num_nodes.to_s
    super
  end
  
end
