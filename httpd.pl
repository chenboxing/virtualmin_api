#!/usr/bin/perl
use Apache::Admin::Config;
use JSON;
use autodie;
use Try::Tiny;
use strict;
use Switch;
  

	
	
	# handle errors with a catch handler
	
	#my %result = (ret_code=>-1, message=>'');
	
	# try{
	
	my %ret = ();		
	my $action = @ARGV[0];	

	
	my $conf = new Apache::Admin::Config("/etc/httpd/conf/httpd.conf",
	 -indent => 2)
	  or die $Apache::Admin::Config::Error;
	
	switch ($action) {
	  case "get_aliases" {
		  %ret = &get_aliases(@ARGV[1]);		  
	  }
	  case "add_alias"   { %ret = &add_alias(@ARGV[1],@ARGV[2]); }
	  case "delete_alias"   { %ret = &delete_alias(@ARGV[1],@ARGV[2]); }
	  case "update_directory_index"   { %ret = &update_directory_index(@ARGV[1],@ARGV[2]); }
	  case "get_directory_index"  {%ret=&get_directory_index(@ARGV[1]); }
	  case "reformat_rails_section"   { %ret = reformat_rails_section(@ARGV[1]); }
	  case "get_rails_environment"   { %ret = get_rails_environment(@ARGV[1],@ARGV[2]); }
	  case "toggle_rails_environment"   { %ret = toggle_rails_environment(@ARGV[1]); }
	  else {
		  $ret{ret_code} = -1;
		  $ret{message}="没有实现方法${action}"
	  }
	}
	
	
	#保存文档 
    $conf->save('-reformat');
	
	#重启apache
	system("apachectl graceful");
	
    
   # }catch{
   #    #warn "caught error: $_"; # not $@
   # 	  $result["ret_code"] = -2;
   # 	  $result["message"] = $_;
   # };
    
	
   my $json = new JSON;
   #$json->sort_by(sub { ncmp($JSON::PP::a, $JSON::PP::b) });
   
   
   my $json_result = $json->pretty->encode (\%ret);
   
   print $json_result,"\n";
	
	


sub alias_exist{

	my $alias_value = $_[0];	  	
	my $alias_exists = "";
	
	#print "alias value_soruce#",$alias_value, "#\n";
	
	foreach my $vh ($conf->section('VirtualHost'))
	{		
		foreach my $alias ($vh->directive('ServerAlias')){
			#print "alias value_",$alias->value, "_\n";
			if($alias->value eq $alias_value){
				$alias_exists = 1;
				last;				
			}
		}
		
		if($alias_exists == 1){
			last
		}
		
	}		
	
	#print "soruce alias_exists",$alias_exists, "\n";
	
	return $alias_exists;
}

# 添加域名绑定
sub add_alias{
	
	my $server_name = $_[0];
	my $alias_name =  $_[1];	
	my %result = (ret_code=>-1,message=>'');	
	
	my $is_alias_has = alias_exist($alias_name);
	#print "alias exists ${is_alias_has}","\n";
	
	if($is_alias_has){
		$result{ret_code} = -1;
		$result{message} = "域名${alias_name}已经存在"		
	}else{
		my $vh = get_vhost($server_name);
		
		if(!defined($vh)){
			$result{message} = "找不到空间${server_name}";
			return %result;
		}
		
		$vh->add_directive(ServerAlias=>$alias_name);
		$result{ret_code} = 0;
	}
	return %result;	
}

# 删除域名绑定
sub delete_alias{
	
	my $server_name = $_[0];
	my $alias_name =  $_[1];
	
	my %result = (ret_code=>-1,message=>'');			
	my $vh = get_vhost($server_name);	
	
	if(!defined($vh)){
		$result{message} = "找不到指定的虚拟主机:${server_name}";
		return %result;
	}	

		
	foreach my $directive ($vh->directive('ServerAlias')){
		if($directive->value eq $alias_name){
			$directive->delete;
		}
	}
	$result{ret_code}= 0;
	
	return %result;	
}

#添加缓存绑定
sub enabled_cache{
	
	my $server_name = $_[0];
	
	my %result = (ret_code=>-1,message=>'');	
  		
	my $vh = get_vhost($server_name);

	if(!defined($vh)){
		$result{message} = "找不到指定的虚拟主机:${server_name}";
		return %result;
	}	
	
	my @rule_directive_names = qw(RewriteEngine RewriteCond RewriteRule);
    foreach my $directory ($vh->section('Directory')){
		if ($directory->value =~ /\/home.*\/public$/) {
        	#Remove all directive in this folder
			#add below directive in this folder			
            foreach my $directive ($directory->directive){												
			  if ( grep { $_ eq  $directive->name  } @rule_directive_names ){         
				 $directive->delete;
			  }	   	   												
            }
									
			#缓存转换规则
			$directory->add_directive(RewriteEngine=>'On');
			$directory->add_directive(RewriteCond=>'%{THE_REQUEST} ^(GET|HEAD)');
			$directory->add_directive(RewriteCond=>'%{DOCUMENT_ROOT}/cache/index.html -f');
			$directory->add_directive(RewriteRule=>'^$ cache/index.html [QSA]');
		   
		    # all other pages
			$directory->add_directive(RewriteCond=>'%{THE_REQUEST} ^(GET|HEAD)');
			$directory->add_directive(RewriteCond=>'%{REQUEST_URI} ^([^.]+?)(.html)?$ [NC]');
			$directory->add_directive(RewriteCond=>'RewriteCond %{DOCUMENT_ROOT}/cache/%1.html -f');
            $directory->add_directive(RewriteRule=>'^([^.]+?)(.html)?$ /cache/$1.html [QSA]');		    				    	 			
        }   
    }
    		
	$result{ret_code} = 0;
	
	return %result;			
}

# 获取绑定的域名
sub get_aliases{
	

	my $server_name = $_[0];
	
	my %result = (ret_code=>-1,message=>'');	
  		
	my $vh = get_vhost($server_name);

	if(!defined($vh)){
		$result{message} = "找不到指定的虚拟主机:${server_name}";
		return %result;
	}	
	
	

	my @arr = ();

	foreach my $directive ($vh->directive('ServerAlias')){
		push @arr, $directive->value;
	}
		
	$result{ret_code} = 0;
    $result{data} = \@arr;

	return %result;

		
}

sub get_vhost{
	
	
	my $server_name = $_[0];
	my $vhost;
	foreach my $vh ($conf->section('VirtualHost'))
	{
	      if($vh->directive('ServerName')->value eq $server_name)
	      {
	          $vhost = $vh;
	          last;
	      }
	}	
	
	return $vhost;	
}


sub reformat_rails_section{

	my $server_name = $_[0];	
	my $vh = get_vhost($server_name);	
	my %result = (ret_code=>-1,message=>'');
	
	if(!defined($vh)){
		$result{message} = "找不到指定的虚拟主机:${server_name}";
		return %result;
	}	

	#删除PHP相关的directive
	my @no_use_directive_names = qw(RemoveHandler FCGIWrapper php_admin_value FcgidMaxRequestLen IPCCommTimeout);
	foreach my $directive ($vh->directive){
		
	    if ( grep { $_ eq  $directive->name  } @no_use_directive_names )
	    {         
	         $directive->delete;
	    }	   	   
	}
	
    foreach my $directory ($vh->section('Directory')){
		if ($directory->value =~ /\/home.*\/public$/) {
        	#Remove all directive in this folder
			#add below directive in this folder			
            foreach my $directive ($directory->directive){
            	$directive->delete;
            }
						
			$directory->add_directive(Allow=>'from all');
			$directory->add_directive(Options=>'-MultiViews');
        }   
    }
    		
	$result{ret_code} = 0;
	
	return %result;
}



# 获取Rails环境
# 返回development 或 production
sub get_rails_environment{
	
	#DirectoryIndex 

    my %result = (ret_code=>-1,message=>'');
	my $server_name = $_[0];	
	my $vh = get_vhost($server_name);
	
	if(!defined($vh)){
		$result{message} = "找不到指定的虚拟主机:${server_name}";
		return %result;
	}	
	
	my $env = $vh->directive("RailsEnv")->value;
	$result{ret_code} = 0;
	$result{data} = $env;	
	return %result;
	
}


#更换rails环境
sub toggle_rails_environment{
	
	#DirectoryIndex 

	my $server_name = $_[0];
	my %result = (ret_code=>-1,message=>'');
    my %ret = get_rails_environment($server_name);
	
	if($ret{ret_code} != 0){
		return %ret;
	}
	
	my $env = $ret{data};	
	my $vh = get_vhost($server_name);
	

		
	if($env eq 'production'){
		my $directive = $vh->directive("RailsEnv");
        $directive->set_value('development');
	}else{
		my $directive = $vh->directive("RailsEnv");
        $directive->set_value('production');

	} 
	
	$result{ret_code} = 0;
	
	return %result; 
	
}

# 更新默认文档
sub update_directory_index{
	
	my %result = (ret_code=>-1,message=>'');
	
	#DirectoryIndex 
	my $server_name = $_[0];
	my $directory_index_value = $_[1];
	
	$directory_index_value =~ s/\,/ /g;
	
	my $vh = get_vhost($server_name);
	
	if(!defined($vh)){
		$result{message} = "找不到虚拟主机${server_name}";
		return %result;
	}
	
	my $d = $vh->directive('DirectoryIndex');
	if(defined($d)){
		$d->set_value($directory_index_value);
	}
	else{
		$vh->add_directive(DirectoryIndex=>$directory_index_value);
	}
		
	$result{ret_code} = 0;
	return %result;
}

#获取默认文档
sub get_directory_index{
	
	my %result = (ret_code=>-1,message=>'');
	
	#DirectoryIndex 
	my $server_name = $_[0];
		
	my $vh = get_vhost($server_name);
	
	if(!defined($vh)){
		$result{message} = "找不到虚拟主机${server_name}";
		return %result;
	}
	
	my $d = $vh->directive('DirectoryIndex');
	
	if(defined($d)){
      $result{data} = $d->value;	   
	}
	$result{ret_code} = 0;
	return %result;
}


# sub add_vhost(conf,host_name){
# 	# adding a new virtual-host:
# 	my $vhost = conf->add_section(VirtualHost=>'127.0.0.1');
# 	$vhost->add_directive(ServerAdmin=>'webmaster@localhost.localdomain');
# 	$vhost->add_directive(DocumentRoot=>'/usr/share/www');
# 	$vhost->add_directive(ServerName=>'chenboxing.seo134.com');
# 	$vhost->add_directive(ErrorLog=>'/var/log/apache/www-error.log');
# 	my $location = $vhost->add_section(Location=>'/admin');
# 	$location->add_directive(AuthType=>'basic');
# 	$location->add_directive(Require=>'group admin');
# 	$conf->save;
#
#
# }




  
 