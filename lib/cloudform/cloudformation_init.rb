require_relative 'template'

# see http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-init.html
class AwsCloudFormationInit
  attr_reader :configs, :config_sets

  def initialize
    clear
  end

  def add_config opt={}
    config = AwsCloudFormationInitConfig.new opt
    @configs.push config
    # register config in default set
    add_config_to_set config
  end

  def add_config_to_set config, set=:default
    @config_sets[set] ||= []
    @config_sets[set].push config.name
  end

  def clear
    @configs = []
    @config_sets = { :default => [] }
  end

  def to_h
    ret = {}
    @configs.each do |config|
      ret[config.name] = config.to_h
    end
    ret[:configSets] = @config_sets
    {
     'AWS::CloudFormation::Init' => ret
    }
  end
  
  # Init processes these configuration sections in the following order: packages, groups, users, sources, files, commands, and then services
  # Packages: rpm, yum/apt, and then no guaranteed ordering of rubygems and python
  # Files are written to disk in lexicographical order
  # Commands are processed in alphabetical order by command element name
  # Other elements are unordered
  class AwsCloudFormationInitConfig
    attr_accessor :name, :commands, :packages, :groups, :users, :sources, :files, :services

    def initialize opt={}
      @name = opt[:name] || 'defaultConfig'
      @groups = opt[:groups] || {}
      @users = opt[:users] || {}
      clear_services
      add_services(opt[:services] || [])
      clear_sources
      add_sources(opt[:sources] || [])
      clear_packages
      add_packages(opt[:packages] || [])
      clear_files
      add_files(opt[:files] || [])
      clear_commands
      add_commands(opt[:commands] || [])
    end

    def add_command opt={}
      opt[:command] || raise('Must specify a command')
      name = opt[:name] || 'Cmd'
      opt.delete :name
      opt[:cwd] ||= '~'
      opt[:ignoreErrors] ||= 'false'

      # add count prefix to commands so they are executed in the order
      # they are added
      count = sprintf '%05d', @commands.size
      name = "#{count}-#{name}"
      
      @commands[name] = opt
    end

    def add_commands commands=[]
      commands.each { |cmd| add_command cmd }
    end

    def clear_commands
      @commands = {}
    end

    def add_file opt={}
      if (opt[:content].nil? and opt[:source].nil?) or (opt[:content] and opt[:source])
        raise 'Must specify either content or URL source'
      end
      location = opt[:location] || "/tmp/defaultFile#{@files.size}.txt"
      opt.delete :location
      opt[:mode] ||= '000664' # rw- rw- r--
      opt[:group] ||= 'root'
      opt[:owner] ||= 'root'
      
      @files[location] = opt
    end
    
    def add_files files=[]
      files.each { |file| add_file file }
    end
    
    def clear_files
      @files = {}
    end

    # Packages are processed in the following order: rpm, yum/apt, and
    # then rubygems and python. There is no ordering between rubygems and
    # python, and packages within each package manager are not 
    # guaranteed to be installed in any order.
    def add_package opt={}
      installers = [:yum, :apt, :msi, :python, :rpm, :rubygems]
      package = opt[:package].to_sym || raise('Must specify package')
      installer = (opt[:installer] || :apt).to_sym
      params = opt[:params] || []
      raise 'Invalid installer' unless installers.include? installer
      
      @packages[installer] ||= {}
      @packages[installer][package] = params
    end

    def add_packages packages=[]
      packages.each { |package| add_package package }
    end
    
    def clear_packages
      @packages = {}
    end
    
    # examples are github (https://github.com/user1/cfn-demo/tarball/master) or
    # s3 bucket (https://s3.amazonaws.com/mybucket/myapp.tar.gz)
    # supported formates are tar, tar+gzip, tar+bz2 and zip
    def add_source opt={}
      url = opt[:url] || raise('Must specify zip/tar URL')
      unzip_dir = opt[:dir] || "/etc/#{@sources.size}_DefaultApp"
      
      @sources[unzip_dir] = url
    end
    
    def add_sources sources=[]
      sources.each { |source| add_source source }
    end

    def clear_sources
      @sources = {}
    end

    def add_service opt={}
      name = opt[:name] || raise('Must specify service name')
      opt.delete :name

      @services[name] = opt      
    end

    def add_services services=[]
      services.each { |service| add_service service }
    end
    
    def clear_services
      @services = {}
    end
    
    def to_h
      ret = {}
      ret[:packages] = @packages unless @packages.empty?
      ret[:groups] = @groups unless @groups.empty?
      ret[:users] = @users unless @users.empty?
      ret[:sources] = @sources unless @sources.empty?
      ret[:files] = @files unless @files.empty?
      ret[:commands] = @commands unless @commands.empty?
      ret[:services] = @services unless @services.empty?
      return ret
    end
  end
  
end
