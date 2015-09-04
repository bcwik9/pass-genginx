require_relative 'resource'
require_relative 'output'

class AwsEc2Instance
  include AwsResource
  
  attr_accessor :commands, :security_groups, :metadata
  
  def initialize opt={}
    @commands = [ "#!/bin/bash -v\n" ]
    opt[:type] = "AWS::EC2::Instance"
    @security_groups = opt[:security_groups] || []
    @metadata = opt[:metadata] || {}
    super opt
  end
  
  # properties for a t2.micro Ubuntu EC2 instance
  def set_default_properties
    @properties = {
      :InstanceType => "t2.micro",
      :ImageId => "ami-d05e75b8"
    }
  end

  def set_image_id ami_id
    raise "Must specify image id" if ami_id.nil? or ami_id.empty?
    add_property :ImageId, ami_id
  end

  def set_instance_type type
    raise "Must specify instance type" if type.nil? or type.empty?
    add_property :InstanceType, type
  end

  # add command to install RVM, ruby, rails, nginx, and passenger
  # works by pulling down script off github and running it
  # see https://raw.githubusercontent.com/bcwik9/ScriptsNStuff/master/setup_dev_server.sh
  def bootstrap
    @commands += [
                  "export HOME=`pwd`" ,"\n",
                  "wget --no-check-certificate https://raw.githubusercontent.com/bcwik9/ScriptsNStuff/master/setup_dev_server.sh && bash setup_dev_server.sh", "\n"
                 ]
  end

  def generate_userdata
    {
      "Fn::Base64" => AwsTemplate.join(@commands)
    }
  end

  def generate_outputs
    [
     AwsOutput.new({:logical_id => "#{@logical_id}Ip", :description => "IP of the EC2 instance #{@logical_id}", :value => get_att(:PublicIp) }),
     AwsOutput.new({:logical_id => "#{@logical_id}Url", :description => "URL of the EC2 instance #{@logical_id}", :value => AwsTemplate.join(['http://', get_att(:PublicDnsName)])})
    ]
  end
  
  def add_security_group security_group
    raise 'Invalid security group' if security_group.nil? or security_group.to_h.empty?
    
    @security_groups.push security_group
  end
  
  def to_h
    @properties[:UserData] = generate_userdata
    
    # link security groups
    @properties[:SecurityGroups] = [] unless @security_groups.empty?
    @security_groups.each do |sg|
      @properties[:SecurityGroups].push sg.get_reference
    end
    
    ret = super

    ret[@logical_id][:Metadata] = @metadata unless @metadata.empty?
    return ret
  end
end
