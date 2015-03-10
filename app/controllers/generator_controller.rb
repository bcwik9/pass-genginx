class GeneratorController < ApplicationController
  require 'cloudform/template'
  require 'cloudform/ec2_resource'
  require 'cloudform/security_group_resource'
  require 'cloudform/wait_handle_resource'
  require 'cloudform/wait_condition_resource'

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
    sg = AwsSecurityGroup.new
    1.times.each do |i|
      ec2 = AwsEc2Instance.new({:name => "testInstance#{i}"})
      ec2.add_security_group sg
      ec2.bootstrap
      template.add_outputs ec2.generate_outputs
      handle = AwsWaitHandle.new
      cond = AwsWaitCondition.new
      cond.set_handle handle
      ec2.properties[:KeyName] = 'laptop'
      cond.depends_on = ec2.name
      ec2.commands += [
                       "cd /home/ubuntu", "\n",
                       "git clone #{github_clone_url}", "\n",
                       "cd #{github_project_name}", "\n",
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

    #{AwsTemplate.get_nginx_server github_project_name, 80, 3000}

    server {
        listen 80;
        server_name  survey.*;
        location / {
           proxy_pass http://localhost:3000;
        }
    }


}\" > temp_nginx.conf", "\n",
                       "sudo mv temp_nginx.conf /opt/nginx/conf/nginx.conf", "\n",
                       "sudo /opt/nginx/sbin/nginx", "\n"
                      ]
      ec2.commands += [
                       "curl -X PUT -H 'Content-Type:' --data-binary '{\"Status\" : \"SUCCESS\",",
                       "\"Reason\" : \"Server is ready\",",
                       "\"UniqueId\" : \"#{ec2.name}\",",
                       "\"Data\" : \"Done\"}' ",
                       "\"", handle.get_reference,"\"\n"
                      ]
      template.add_resources [ec2, handle, cond]
    end
    template.add_resource sg
    render :json => template.to_json
  end
end
