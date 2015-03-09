require_relative 'ec2_resource'
require_relative 'security_group_resource'

template = AwsTemplate.new
ec2 = AwsEc2Resource.new
sg = AwsSecurityGroup.new

ec2.add_security_group sg

# add everything to template
template.add_resources [ec2, sg]

puts ec2.to_json

