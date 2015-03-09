class GeneratorController < ApplicationController
  require 'cloudform/template'
  require 'cloudform/ec2_resource'
  require 'cloudform/security_group_resource'

  def index
  end
  
  def json_gen
    # check github url param
    github_clone_url = params[:github_repo].first
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

    # render the json
    #send_data cloudformation_template(github_project_name, github_clone_url, nil), filename: "#{github_project_name}.json", type: :json
    #render :json => AwsTemplate.cloudformation_template(github_project_name, github_clone_url, "laptop")
    template = AwsTemplate.new
    ec2 = AwsEc2Resource.new
    sg = AwsSecurityGroup.new
    ec2.add_security_group sg
    template.add_resources [ec2, sg]
    template.add_outputs ec2.generate_outputs
    render :json => template.to_json
  end
end
