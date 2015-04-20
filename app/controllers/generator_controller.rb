class GeneratorController < ApplicationController
  require 'cloudform/template'
  require 'cloudform/parameter'
  require 'cloudform/ec2_resource'
  require 'cloudform/security_group_resource'
  require 'cloudform/wait_handle_resource'
  require 'cloudform/wait_condition_resource'
  require 'cloudform/eb_application_version_resource'
  require 'cloudform/eb_application_resource'
  require 'cloudform/eb_config_template_resource'
  require 'cloudform/eb_environment_resource'

  def index
  end
  
  def json_gen
    eb_app_call
    return

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

    # create a blank template
    template = AwsTemplate.new

    # create default security group to associate with our ec2 instances
    sg = AwsSecurityGroup.new
    # add it to the template
    template.add_resource sg
    # remove (default) access to port 22 since we don't need to SSH
    sg.remove_access 22

    # create x number of ec2 instances and associated wait handles
    1.times.each do |i|
      # instantiate new ec2 instance
      ec2 = AwsEc2Instance.new({:logical_id => "testInstance#{i}"})
      # associate the security group we created before with the new instance
      ec2.add_security_group sg
      # add some basic outputs
      template.add_outputs ec2.generate_outputs
      # create new wait handle and wait condition
      handle = AwsWaitHandle.new
      cond = AwsWaitCondition.new
      # associate wait condition/handle and ec2 
      cond.set_handle handle
      cond.depends_on = ec2.logical_id
      # add commands to set up ec2 instance with rvm/rails/nginx/git etc
      ec2.bootstrap
      # set up rails github project on ec2 server
      ec2.commands += [
                       "cd /home/ubuntu", "\n",
                       "bash --login /usr/local/rvm/bin/rvmsudo git clone #{github_clone_url}", "\n",
                       "cd #{github_project_name}", "\n",
                       "bash --login /usr/local/rvm/bin/rvmsudo bundle install", "\n",
                       "bash --login /usr/local/rvm/bin/rvmsudo rake db:migrate", "\n",
                       "sudo chmod -R 777 /home/ubuntu/#{github_project_name}", "\n"
                       #"bash --login /usr/local/rvm/bin/rvmsudo bundle exec rails server -b 0.0.0.0 -d", "\n"
                      ]
      # set up nginx with rails project
      ec2.commands += [
                       "wget --no-check-certificate https://raw.githubusercontent.com/bcwik9/ScriptsNStuff/master/add_nginx_servers.rb && bash --login /usr/local/rvm/bin/rvmsudo ruby add_nginx_servers.rb 80:/home/ubuntu/#{github_project_name}/public", "\n",
                       "sudo /opt/nginx/sbin/nginx", "\n"
                      ]
      # notify that everything is done
      ec2.commands += [
                       "curl -X PUT -H 'Content-Type:' --data-binary '{\"Status\" : \"SUCCESS\",",
                       "\"Reason\" : \"Server is ready\",",
                       "\"UniqueId\" : \"#{ec2.logical_id}\",",
                       "\"Data\" : \"Done\"}' ",
                       "\"", handle.get_reference,"\"\n"
                      ]
      # add everything we just created to the template
      template.add_resources [ec2, handle, cond]
    end
    
    # display the template as JSON
    render :json => template.to_json

    # download json directly
    #send_data template.to_json, filename: "#{github_project_name}.json", type: :json
  end

  def eb_app_call
    eb_app = AwsElasticBeanstalkApplication.new

    eb_version = AwsElasticBeanstalkApplicationVersion.new
    eb_version.set_application_name eb_app.get_reference
    eb_version.set_source 'elasticbeanstalk-us-east-1-719719598906', 'questionnaire-forms-master.zip'

    eb_config = AwsElasticBeanstalkConfigurationTemplate.new
    eb_config.set_application_name eb_app.get_reference
    eb_config.enable_single_instance
    eb_config.set_image_id 'ami-26b9834e' # bitnami ruby stack
    eb_config.set_instance_type 't2.micro'

    eb_env = AwsElasticBeanstalkEnvironment.new
    eb_env.set_application_name eb_app.get_reference
    eb_env.set_template_name eb_config.get_reference
    eb_env.set_version_label eb_version.get_reference
    
    # create a blank template and add all the resources we need
    template = AwsTemplate.new
    template.add_resources [eb_app, eb_version, eb_config, eb_env]

    render :json => template.to_json
  end
end
