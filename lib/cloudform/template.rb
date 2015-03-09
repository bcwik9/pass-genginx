require 'json'

class AwsTemplate
  attr_accessor :format_version, :resources, :outputs
  
  def initialize opt={}
    @format_version = opt[:format_version] || "2010-09-09"
    @resources = opt[:resources] || []
    @outputs = opt[:outputs] || []
  end

  def add_resource resource
    raise 'Resource was nil or empty' if resource.nil? or resource.to_h.empty?
    @resources.push resource
  end

  def add_resources resources
    resources.each do |resource|
      add_resource resource
    end
  end

  def add_output output
    raise 'Output was nil or empty' if output.nil? or output.to_h.empty?

    @outputs.push output
  end
  
  # essentially merges a list of hashes
  def prepare_section arr
    ret = {}
    arr.each { |i| ret.merge! i.to_h }
    return ret
  end
  
  def to_h
    {
      :AWSTemplateFormatVersion => @format_version,
      :Resources => prepare_section(@resources),
      :Outputs => prepare_section(@outputs)
    }
  end

  def to_json
    to_h.to_json
  end
  
  def self.cloudformation_template project_name, clone_url, keypair_name, instance_type="t2.micro", image_id="ami-9a562df2"
    safe_name = (project_name + rand(99999999).hash.to_s).gsub(/[^a-z0-9\s]/i, '') # remove punctuation
    {
      "AWSTemplateFormatVersion" => "2010-09-09",
      
      "Resources" => {
        "#{safe_name}ec2" => {
          "Type" => "AWS::EC2::Instance",
          "Properties" => {
            "KeyName" => keypair_name,
            "InstanceType"=> instance_type,
            "SecurityGroups" => [ { "Ref" => "#{safe_name}sg" } ],
            "ImageId" => image_id,
            "UserData" => {
              "Fn::Base64" => join([
                                    "#!/bin/bash -v\n",
                                    "export HOME=`pwd`" ,"\n",
                                    "wget --no-check-certificate https://raw.githubusercontent.com/bcwik9/ScriptsNStuff/master/setup_dev_server.sh && bash setup_dev_server.sh", "\n",
                                    "cd /home/ubuntu", "\n",
                                    "git clone #{clone_url}", "\n",
                                    "cd #{project_name}", "\n",
                                    "bash --login /usr/local/rvm/bin/rvmsudo bundle install", "\n",
                                    "bash --login /usr/local/rvm/bin/rvmsudo rake db:migrate", "\n",
                                    "bash --login /usr/local/rvm/bin/rvmsudo bundle exec rails server -b 0.0.0.0 -d", "\n",
                                    "echo \"
#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    passenger_root /var/lib/gems/1.9.1/gems/passenger-4.0.59;
    passenger_ruby /usr/bin/ruby1.9.1;

    passenger_app_env development;

    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    keepalive_timeout  65;

    #{get_nginx_server project_name, 80, 3000}

    server {
        listen 80;
        server_name  survey.*;
        location / {
           proxy_pass http://localhost:3000;
        }
    }


}\" > temp_nginx.conf", "\n",
                                    "sudo mv temp_nginx.conf /opt/nginx/conf/nginx.conf", "\n",
                                    "sudo /opt/nginx/sbin/nginx", "\n",
                                    "curl -X PUT -H 'Content-Type:' --data-binary '{\"Status\" : \"SUCCESS\",",
                                    "\"Reason\" : \"Server is ready\",",
                                    "\"UniqueId\" : \"#{safe_name}ec2\",",
                                    "\"Data\" : \"Done\"}' ",
                                    "\"", {"Ref" => "WaitForInstanceWaitHandle"},"\"\n"
                                   ])
              
            },
            "Tags"=> [
                      {
                        "Key"=> "Name",
                        "Value"=> project_name
                      },
                      {
                        "Key"=> "branch_name",
                        "Value"=> "master"
                      },
                      {
                        "Key"=> "environment",
                        "Value"=> "development"
                      },
                      {
                        "Key"=> "db_type",
                        "Value"=> "sqlite"
                      },
                      {
                        "Key"=> "deployer",
                        "Value"=> "ubuntu"
                      }
                      
                     ]
          }
        },
        
        "#{safe_name}sg" => {
          "Type" => "AWS::EC2::SecurityGroup",
          "Properties" => {
            "GroupDescription" => "Enable Access to Rails application via port 80 and 443",
            "SecurityGroupIngress" => [ {
                                          "IpProtocol" => "tcp",
                                          "FromPort" => "22",
                                          "ToPort" => "22",
                                          "CidrIp" => "0.0.0.0/0"
                                        },
                                        {
                                          "IpProtocol" => "tcp",
                                          "FromPort" => "80",
                                          "ToPort" => "80",
                                          "CidrIp" => "0.0.0.0/0"
                                        },
                                        {
                                          "IpProtocol" => "tcp",
                                          "FromPort" => "443",
                                          "ToPort" => "443",
                                          "CidrIp" => "0.0.0.0/0"
                                        },
                                        {
                                          "IpProtocol" => "tcp",
                                          "FromPort" => "3000",
                                          "ToPort" => "3000",
                                          "CidrIp" => "0.0.0.0/0"
                                        }],
            "Tags" => [
                       {
                         "Key"=> "Name",
                         "Value"=> project_name
                       },
                       {
                         "Key"=> "branch_name",
                         "Value"=> "master"
                       },
                       {
                         "Key"=> "environment",
                         "Value"=> "development"
                       },
                       {
                         "Key"=> "db_type",
                         "Value"=> "sqlite"
                       },
                       {
                         "Key"=> "deployer",
                         "Value"=> "ubuntu"
                       }
                       
                      ]
          }
        },
        
        "WaitForInstanceWaitHandle" => {
          "Type" => "AWS::CloudFormation::WaitConditionHandle",
          "Properties" => { }
        },
        
        "WaitForInstance" => {
          "Type" => "AWS::CloudFormation::WaitCondition",
          "DependsOn" => "#{safe_name}ec2",
          "Properties" => {
            "Handle" => {"Ref" => "WaitForInstanceWaitHandle"},
            "Timeout" => "800"
          }
        }
      },
      
      "Outputs" => {
        "IP" => {
          "Description" => "The IP for the newly created server",
          "Value" => { "Fn::GetAtt" => [ "#{safe_name}ec2", "PublicIp" ] } 
        },
        "WebsiteURL" => {
          "Description" => "The URL for the newly created Rails application",
          "Value" => join([ "http://", { "Fn::GetAtt" => [ "#{safe_name}ec2", "PublicDnsName" ] } ])
        },
        "SurveyURL" => {
          "Description" => "The URL for the newly created Survey application",
          "Value" => join( [ "http://", { "Fn::GetAtt" => [ "#{safe_name}ec2", "PublicDnsName" ] }, ":3000" ] )
        }
      }
    }.to_json
  end

  
  def self.join arr, delim=""
    {
      "Fn::Join" => [
                     delim,
                     arr
                    ]
    }
  end

  private
  
  def self.get_nginx_server project_name, listen_port, forward_port
    "server {
        #listen #{listen_port};
        server_name  localhost;
        #passenger_enabled on;
        #root /home/ubuntu/#{project_name}/public;

        location / {
           proxy_pass http://localhost:#{forward_port};
        }
    }"
  end
end
