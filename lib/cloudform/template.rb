require 'json'

class AwsTemplate
  attr_accessor :format_version, :description, :resources, :outputs, :parameters
  
  def initialize opt={}
    @format_version = opt[:format_version] || '2010-09-09'
    @description = opt[:description] || 'Example AWS Cloudformation template'
    @resources = opt[:resources] || []
    @outputs = opt[:outputs] || []
    @parameters = opt[:parameters] || []
  end

  def add_resource resource
    raise 'Resource was nil or empty' if resource.nil? or resource.to_h.empty?
    @resources.push resource
  end

  def add_resources resources
    resources.each { |r| add_resource r }
  end
  
  def add_output output
    raise 'Output was nil or empty' if output.nil? or output.to_h.empty?
    
    @outputs.push output
  end
  
  def add_outputs outputs
    outputs.each { |o| add_output o }
  end

  def add_parameter parameter
    raise 'Parameter was nil or empty' if parameter.nil? or parameter.to_h.empty?
    
    @parameters.push parameter
  end
  
  def add_parameters parameters
    parameters.each { |p| add_parameter p }
  end

  def self.generate_statement opt={}
    options = capitalize_keys opt
    raise 'Must specify action' unless options[:Action]
    options[:Effect] = 'Allow' if options[:Effect].nil? or options[:Effect].empty?

    {
      :Statement => [options]
    }
  end
  
  def self.generate_reference ref
    {
      :Ref => ref
    }
  end

  def self.region_reference
    generate_reference "AWS::Region"
  end

  # capitalize first letter of all keys in a hash
  def self.capitalize_keys h
    ret = {}

    h.each do |k,v|
      new_key = capitalize_symbol k
      ret[new_key] = v
    end

    return ret
  end

  # capitalize first letter of a symbol
  def self.capitalize_symbol s
    return '' if s.empty?
    new_string = s.to_s.split ''
    new_string[0].upcase!
    new_string.join.to_sym
  end
  
  # takes a list of AWS objects, each with their own to_h method, and
  # returns a hash representaion of the objects
  # essentially merges a list of hashes
  def prepare_section arr
    ret = {}
    arr.each { |i| ret.merge! i.to_h }
    return ret
  end
    
  def to_h
    # Resources is the only required section
    ret = {
      :AWSTemplateFormatVersion => @format_version,
      :Description => @description,
      :Resources => prepare_section(@resources),
    }
    ret[:Parameters] = prepare_section(@parameters) unless @parameters.empty?
    ret[:Outputs] = prepare_section(@outputs) unless @outputs.empty?

    return ret
  end

  def to_json
    to_h.to_json
  end

  def self.join arr, delim=""
    {
      "Fn::Join" => [
                     delim,
                     arr
                    ]
    }
  end

  def self.get_nginx_server project_name, listen_port, forward_port
    "server {
        #listen #{listen_port};
        server_name  localhost;
        passenger_enabled on;
        root /home/ubuntu/#{project_name}/public;

        #location / {
        #   proxy_pass http://localhost:#{forward_port};
        #}
    }"
  end
end
