require_relative 'resource'

class AwsElastiCacheParameterGroup
  include AwsResource

  attr_accessor :description, :family

  def initialize opt={}
    opt[:type] = "AWS::ElastiCache::ParameterGroup"
    @description = opt[:description] || "Example ElastiCache Parameter Group"
    @family = opt[:family] || raise "Must specify family (CacheParameterGroupFamily"
  end

  def to_h
    add_property :Description, @description
    add_property :CacheParameterGroupFamily, @family
    super
  end
end
