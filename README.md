# Ruby on Rails/AWS Cloudformation Generator
### http://railscloudform.bencwik.com

## About
Tool which takes a github clone URL to a basic Ruby on Rails project and spits out a AWS Cloudformation JSON template which can instantly be uploaded to Amazon. The template contains instructions to provision a EC2 instance (ie. server the project will run on), bootstrap the server (ie. install ruby/rails/RVM/nginx/passenger/git), set up the Rails project, configure nginx (complete with Phusion Passenger support), and start everything. The template outputs a URL to the newly hosted project so it can be viewed from any browser.

## Creating a Custom Template
Under /lib/cloudform/, there are a few important ruby scripts. These represent various entities related to AWS Cloudformation templates. To see how they are used, let's look at an example of how to set up a basic Rails EC2 development server:
```ruby
# Requires needed for a Amazon AWS EC2 instance and Security Group
require_relative 'ec2_resource'
require_relative 'security_group_resource'

# Also require AWS parameter, so we can prompt for a SSH keypair
require_relative 'parameter'


# Start by creating a blank Cloudformation JSON tempate
template = AwsTemplate.new

# Now let's create our EC2 instance, which defaults to t2.micro Ubuntu
ec2_instance = AwsEc2Instance.new

# Add our new server to the template
template.add_resource ec2_instance

# Security is important, right?
# Let's create a new Security Group
# This will let us control which ports recieve traffic on our EC2 server
# Default is 22(SSH), 80(HTTP), and 443(HTTPS)
security_group = AwsSecurityGroup.new

# We'll be testing a Rails app on port 3000, so let's open that as well
security_group.add_inbound_access 3000

# Add the security group to the template
template.add_resource security_group

# Now associate the security group with our EC2 instance
ec2_instance.add_security_group security_group

# We're going to be developing on this server
# so let's create a param which will prompt for a keypair to use for SSH
keypair_param = AwsParameter.new(:type => "AWS::EC2::KeyPair::KeyName")

# Add the parameter to the template
template.add_parameter keypair_param

# Now we simply add the keypair reference to our EC2 instance
ec2_instance.properties[:KeyName] = keypair_param.get_reference

# We're done! Let's print out the ready to use json template
puts template.to_json

```

Here's the Amazon AWS Cloudformation ready JSON:
```json
{
    AWSTemplateFormatVersion: "2010-09-09",
    Description: "Example AWS Cloudformation template",
    Resources: {
	defaultAwsEc2Instance: {
	    Type: "AWS::EC2::Instance",
	    Properties: {
		InstanceType: "t2.micro",
		ImageId: "ami-9a562df2",
		Tags: [
		    {
			Key: "Name",
			Value: "defaultAwsEc2Instance"
		    },
		    {
			Key: "deployer",
			Value: "ubuntu"
		    }
		],
		UserData: {
		    Fn::Base64: {
			Fn::Join: [
			    "",
			    [
				"#!/bin/bash -v "
			    ]
			]
		    }
		},
		SecurityGroups: [
		    {
			Ref: "defaultAwsSecurityGroup"
		    }
		],
		KeyName: {
		    Ref: "defaultAwsParameter"
		}
	    }
	},
	defaultAwsSecurityGroup: {
	    Type: "AWS::EC2::SecurityGroup",
	    Properties: {
		GroupDescription: "Enable access to port(s): 22,80,443,",
		SecurityGroupIngress: [
		    {
			IpProtocol: "tcp",
			FromPort: 22,
			ToPort: 22,
			CidrIp: "0.0.0.0/0"
		    },
		    {
			IpProtocol: "tcp",
			FromPort: 80,
			ToPort: 80,
			CidrIp: "0.0.0.0/0"
		    },
		    {
			IpProtocol: "tcp",
			FromPort: 443,
			ToPort: 443,
			CidrIp: "0.0.0.0/0"
		    },
		    {
			IpProtocol: "tcp",
			FromPort: 3000,
			ToPort: 3000,
			CidrIp: "0.0.0.0/0"
		    }
		],
		Tags: [
		    {
			Key: "Name",
			Value: "defaultAwsSecurityGroup"
		    },
		    {
			Key: "deployer",
			Value: "ubuntu"
		    }
		]
	    }
	}
    },
    Parameters: {
	defaultAwsParameter: {
	    Description: "Example AWS Parameter",
	    Type: "AWS::EC2::KeyPair::KeyName"
	}
    }
}
```