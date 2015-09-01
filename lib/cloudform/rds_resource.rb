require_relative 'rds_security_group_resource'

class AwsRdsInstance
  include AwsResource
  
  attr_accessor :allocated_storage, :engine, :instance_class, :username, :password

  VALID_ENGINES = %w[ MySQL oracle-se1 oracle-se oracle-ee sqlserver-ee sqlserver-se sqlserver-ex sqlserver-web postgres ]
  STORAGE_TYPES = %w[ standard gp2 io1 ]
  
  # defaults to a t2.micro 5GB postgres
  def initialize opt={}
    opt[:type] = "AWS::RDS::DBInstance"
    super opt

    @instance_class = opt[:instance_class] || 'db.t2.micro'
    @engine = opt[:engine] || 'postgres'
    @allocated_storage = opt[:allocated_storage] || 5 #5GB minimum
    @username = opt[:username] || 'postgres'
    @password = opt[:password] || 'password'
    add_property :PubliclyAccessible, opt[:publicly_accessible] || false
    add_property :StorageType, opt[:storage_type] || 'gp2'
  end

  def add_db_security_group group
    @properties[:DBSecurityGroups] ||= []
    if group.type == "AWS::EC2::SecurityGroup"
      # create a DB Security Group
      group = AwsRdsSecurityGroup.new(ec2_security_groups: [group])
    end
    @properties[:DBSecurityGroups].push group.get_reference
    return group
  end

  def clear_db_security_groups
    @properties.delete :DBSecurityGroups
  end

  def add_vpc_security_group group
    @properties[:VPCSecurityGroups] ||= []
    @properties[:VPCSecurityGroups].push group.get_reference
  end

  def clear_vpc_security_groups
    @properties.delete :VPCSecurityGroups
  end

  def to_h
    raise "Allocated storage must be a minimum of 5GB" if @allocated_storage.to_i < 5
    raise "Invalid engine specified" unless VALID_ENGINES.include? @engine
    raise "Invalid storage type" unless STORAGE_TYPES.include? get_property(:StorageType)

    add_property :Engine, @engine
    add_property :AllocatedStorage, @allocated_storage.to_i
    add_property :DBInstanceClass, @instance_class
    add_property :MasterUsername, @username
    add_property :MasterUserPassword, @password
    super
  end

end
