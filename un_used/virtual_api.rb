module VirtualAPI
  class << self
	  def get_all_hosts

	    #content_type :json
            output= `wget -O - --quiet --http-user=root --http-passwd=loveamy1314 --no-check-certificate \"https://192.168.1.60:10000/virtual-server/remote.cgi?program=list-domains&json=1\"`
            result=$?.success?
            #system `wget -O - --quiet --http-user=root --http-passwd=loveamy1314 --no-check-certificate \"https://192.168.1.60:10000/virtual-server/remote.cgi?program=list-domains&json=1\"`
	    output
    end

    def call_api(method,parameters={})

    end

	  def authenticate
      #Check call IP
      #Check MD5 string using md5 keys
	      #Logger.new(STDOUT)
	      #　logger = Logger.new('foo.log', 10, 1024000) #保留10个日志文件，每个文件大小1024000字节
	      logger = Logger.new('app.log', 'daily') #按天生成
	      #logger.level = Logger::INFO #fatal、error、warn、info、debug
	      # logger.formatter = proc { |severity, datetime, progname, msg|
	      #   "#{datetime}: #{msg}\n"
	      # }
	     #logger.info 'asdfasd'
	  end

  end
end
