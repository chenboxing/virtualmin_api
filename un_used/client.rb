require 'rest_client'
require 'json'

# parameters = {params:{
#     domain: 'axisoft.cn',
#     pass: 'loveamy1314',
#     desp: 'axisoft',
#     plan: 'Default Plan',
#     email: '36821277@qq.com',
#     user: 'axisoft',
#     web: 1,
#     ftp: 1,
#     'virtualmin-awstats'=> 1,
#     ssl: 1,
#     mysql: 1,
#     db: 'axisoft',
#     'mysql-pass' => 'loveamy1314',
#     "default-features" => 1,
#     "features-from-plan" => 1,
#     template: 'Default Settings'}}

def test_create_domain

  parameters = {params:{
      domain: 'axisoft123.com',
      pass: 'loveamy1314',
      template: 'php_template',
      plan: 'BasicPlan',
      desp: 'axisoft',
      web: '',
      unix:'',
      dir:'',
#      mysql:'',
      'virtualmin-awstats'=>'',
      'limits-from-plan'=>''
  }}

  result = RestClient.get 'http://192.168.1.60:3005/create_domain',parameters
  #p result.code
  p result.to_str
end

def test_delete_domain
  result = RestClient.delete 'http://192.168.1.60:3004/domain', {params: {domain:'axisoft.cn'}}
  p result.to_str
end

def test_enable_domain
  parameters = {params:{
      domain: 'axisoft.com'
  }}

  result = RestClient.get 'http://192.168.1.60:3005/enable_domain',parameters
  #p result.code
  p result.to_str
  	
end

def test_disable_domain
  
  #begin
  #rescue RestClient::ResourceNotFound
  #end

  parameters = {params:{
      domain: 'axisoft.com'
  }}

  result = RestClient.get 'http://192.168.1.60:3005/disable_domain', {params: {domain:'axisoft.com',why:'only for test'}}
  #p result.code
  p result.to_str
end


def test_modify_domain
  parameters = {
      domain: 'axisoft.cn',
      pass: 'axis&$in fo'
  }

  result = RestClient.post 'http://192.168.1.60:3005/modify_domain',parameters
  #p result.code
  p result.to_str

end

#test_create_domain
#test_disable_domain
#test_enable_domain
test_modify_domain
#test_delete_domain

#obj1 = JSON.parse(result.to_str)
#p obj1['full_error']

#wget --no-check-certificate --http-user=root --http-passwd=password 'https://localhost:10000/virtual-server/remote.cgi?program=create-domain&domain=foo.com&pass=smeg&desc=The server for foo&unix&dir&webmin&web&dns&mail&limits-from-plan'

