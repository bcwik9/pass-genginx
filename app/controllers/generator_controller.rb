class GeneratorController < ApplicationController
  require 'json'

  def index
  end
  
  def json_gen
    # check github url param
    github_clone_url = params[:github_repo]
    if github_clone_url.nil? or github_clone_url.empty?
      redirect_to root_path, notice: "Invalid Github URL"
      return
    end
    if github_clone_url =~ /github\.com\/(.+)\/(.*)\.git/
      github_account = $1
      github_project_name = $2
    else
      redirect_to root_path, notice: "Invalid Github URL"
      return
    end

    # check keypair param
    keypair_name = params[:keypair]
    if keypair_name.nil? or keypair_name.empty?
      redirect_to root_path, notice: "Invalid keypair name"
      return
    end

    # render the json
    render :json => cloudformation_template(github_project_name, github_clone_url, keypair_name)
  end

  private
  def cloudformation_template project_name, clone_url, keypair_name, instance_type="t2.micro", image_id="ami-9a562df2"
    safe_name = project_name.gsub(/[^a-z0-9\s]/i, '') # remove punctuation
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
              "Fn::Base64" => {
                "Fn::Join" => ["",[
                                   "#!/bin/bash -v\n",
                                   "export HOME=`pwd`" ,"\n",
                                   "wget --no-check-certificate https://raw.githubusercontent.com/bcwik9/ScriptsNStuff/master/setup_dev_server.sh && bash setup_dev_server.sh", "\n",
                                   "git clone #{clone_url}", "\n",
                                   "cd #{project_name}", "\n",
                                   "bundle install", "\n",
                                   "rake db:migrate", "\n",
                                   "bundle exec rails server -b 0.0.0.0 -d", "\n",
                                   "curl -X PUT -H 'Content-Type:' --data-binary '{\"Status\" : \"SUCCESS\",",
                                   "\"Reason\" : \"Server is ready\",",
                                   "\"UniqueId\" : \"#{safe_name}ec2\",",
                                   "\"Data\" : \"Done\"}' ",
                                   "\"", {"Ref" => "WaitForInstanceWaitHandle"},"\"\n"
                                  ]]
              }
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
            "GroupDescription" => "Enable Access to Rails application via port 80, 443, 3000 and SSH access via port 22",
            "SecurityGroupIngress" => [ {
                                          "IpProtocol" => "tcp",
                                          "FromPort" => "22",
                                          "ToPort" => "22",
                                          "CidrIp" => "0.0.0.0/0"
                                        }, {
                                          "IpProtocol" => "tcp",
                                          "FromPort" => "3000",
                                          "ToPort" => "3000",
                                          "CidrIp" => "0.0.0.0/0"
                                        }, {
                                          "IpProtocol" => "tcp",
                                          "FromPort" => "80",
                                          "ToPort" => "80",
                                          "CidrIp" => "0.0.0.0/0"
                                        } , {
                                          "IpProtocol" => "tcp",
                                          "FromPort" => "443",
                                          "ToPort" => "443",
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
            "Timeout" => "600"
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
          "Value" => { "Fn::Join" => ["", [ "http://", { "Fn::GetAtt" => [ "#{safe_name}ec2", "PublicIp" ] } ]]}
        }
      }
    }.to_json
  end
end
