require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'json'

#name = "/C=US/ST=SomeState/L=SomeCity/O=Organization/OU=Unit/CN=localhost"
name = "/C=CN/ST=GUANGDONG/L=ZHUHAI/O=DAYSNET/OU=IT/CN=localhost"
ca   = OpenSSL::X509::Name.parse(name)
key = OpenSSL::PKey::RSA.new(1024)
crt = OpenSSL::X509::Certificate.new
crt.version = 2
crt.serial  = 1
crt.subject = ca
crt.issuer = ca
crt.public_key = key.public_key
crt.not_before = Time.now
crt.not_after  = Time.now + 1 * 365 * 24 * 60 * 60 # 1 year
webrick_options = {
    :Port               => 3000,
    :Daemon             => true,
    :Logger => WEBrick::Log.new("web.log",WEBrick::Log::INFO),
    :AccessLog => [[File.open("web.log",'w'),WEBrick::AccessLog::COMBINED_LOG_FORMAT]],
    :SSLEnable          => false,
    :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
    :SSLCertificate     => crt,
    :SSLPrivateKey      => key,
    :SSLCertName        => [[ "CN", WEBrick::Utils::getservername ]],
}
def agg_lines(data)
    data.each_line.collect{|x| "  >> #{x}" }.join
end
class MyServer < Sinatra::Base

    get '/' do      
      content_type :json
      attr = {username: 'chen', age:13}
      attr.to_json
      # "Hello World!\n"
    end

    get '*' do |x|
        "GET of URI #{x}\n"
    end

    post "*" do |x|
        request.body.rewind
        "POST to URI #{x}\n#{agg_lines(request.body.read)}\n"
    end
end
server = ::Rack::Handler::WEBrick
trap(:INT) do
    server.shutdown
end
server.run(MyServer, webrick_options)
