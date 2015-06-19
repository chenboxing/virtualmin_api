re File.dirname(__FILE__) + '/../config/boot'    
    require 'webrick'    
    # 包含必须的库  
    require 'webrick/https'    
    require 'optparse'    
    puts "=> Booting WEBrick..."    
    OPTIONS = {    
    # 端口号  
      :port         => 3001,    
    # 监听主机地址  
      :Host         => "0.0.0.0",    
      :environment  => (ENV['RAILS_ENV'] || "development").dup,    
    # 存放redmine中public的路径，这里采用相对路径，保证可移植性  
      :server_root  => File.expand_path(File.dirname(__FILE__) + "/../public/"),    
    # 存放私钥的地址  
      :pkey         => OpenSSL::PKey::RSA.new(    
                          File.open(File.dirname(__FILE__) + "/../config/certs/server.key").read),    
    # 存放签名证书的地址  
      :cert         => OpenSSL::X509::Certificate.new(    
                          File.open(File.dirname(__FILE__) + "/../config/certs/server.crt").read),    
      :server_type  => WEBrick::SimpleServer,    
      :charset      => "UTF-8",    
      :mime_types   => WEBrick::HTTPUtils::DefaultMimeTypes,    
      :config       => RAILS_ROOT + "/config.ru",    
      :detach       => false,    
      :debugger     => false,    
      :path         => nil    
    }    
    # 以下读入命令行参数  
    ARGV.clone.options do |opts|    
      opts.on("-p", "--port=port", Integer,    
              "Runs Rails on the specified port.", "Default: 3001") { |v| OPTIONS[:Port] = v }    
      opts.on("-b", "--binding=ip", String,    
              "Binds Rails to the specified ip.", "Default: 0.0.0.0") { |v| OPTIONS[:Host] = v }    
      opts.on("-d", "--daemon", "Make server run as a Daemon.") { OPTIONS[:detach] = true }    
      opts.on("-u", "--debugger", "Enable ruby-debugging for the server.") { OPTIONS[:debugger] = true }    
      opts.on("-e", "--environment=name", String,    
              "Specifies the environment to run this server under (test/development/production).",    
              "Default: development") { |v| OPTIONS[:environment] = v }    
      opts.separator ""    
      opts.on("-h", "--help", "Show this help message.") { puts opts; exit }    
      opts.parse!    
    end    
    # 设置启动环境，production或development等  
    ENV["RAILS_ENV"] = OPTIONS[:environment]    
    RAILS_ENV.replace(OPTIONS[:environment]) if defined?(RAILS_ENV)    
    # 读取redmine配置文件  
    require File.dirname(__FILE__) + "/../config/environment"    
    require 'webrick_server'    
    require 'webrick/https'    
    OPTIONS['working_directory'] = File.expand_path(File.dirname(__FILE__))    
    # 初始化带SSL的webrick服务器  
    class SSLDispatchServlet < DispatchServlet    
      def self.dispatch(options)    
        Socket.do_not_reverse_lookup = true    
        server = WEBrick::HTTPServer.new(    
          :Port             => options[:port].to_i,    
          :ServerType       => options[:server_type],    
          :BindAddress      => options[:Host],    
          :SSLEnable        => true,    
          :SSLVerifyClient  => OpenSSL::SSL::VERIFY_NONE,    
          :SSLCertificate   => options[:cert],    
          :SSLPrivateKey    => options[:pkey],    
          :SSLCertName      => [ [ "CN", WEBrick::Utils::getservername ] ]    
        )    
        server.mount('/', DispatchServlet, options)    
        trap("INT") { server.shutdown }    
        server.start    
      end    
    end    
    # 输出启动提示  
    puts "=> Rails #{Rails.version} application starting on https://#{OPTIONS[:Host]}:#{OPTIONS[:port]}"    
    # 如果用户在命令行输入“-d”参数，则程序将在后台运行  
    if OPTIONS[:detach]    
      Process.daemon    
      pid = "#{RAILS_ROOT}/tmp/pids/server.pid"    
      File.open(pid, 'w'){ |f| f.write(Process.pid) }    
      at_exit { File.delete(pid) if File.exist?(pid) }    
    end    
    # 没有“-d”参数时在终端输出提示，此时可以通过“ctrl+c”关闭服务器  
    puts "=> Call with -d to detach"    
    trap(:INT) { exit }    
    puts "=> Ctrl-C to shutdown"    
    # 启动webrick服务器  
    SSLDispatchServlet.dispatch(OPTIONS)   
