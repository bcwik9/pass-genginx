class GeneratorController < ApplicationController
  require 'cloudform/examples/templates'

  def index
  end
  
  def json_gen
    # use a template instead
    #template = ec2_with_elasticache_template
    #template = ec2_with_cfn_init_template
    #template = basic_ec2_with_sg_template
    template = ec2_codedeploy_template
    render :json => template.to_json
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
    sg.remove_access(:from => 22)

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

end
