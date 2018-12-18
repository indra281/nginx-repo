# == Class: nginx::extensions::signalsciences

class nginx::extensions::signalsciences (
  $config = undef
)
{
  if ($config != undef)
  {
    if ($::operatingsystem == 'centos')
    {
      # Fill Variables
      $signal_sciences_agent = $config['signal_sciences_module']
      $signal_sciences_nginx_module = $config['signal_sciences_nginx_module']
      $access_key = $config['signal_sciences_accesskey']
      $secret_key = $config['signal_sciences_secretkey']

      # Install Lua
      package { 'nginx-lua-module':
        ensure => installed,
        name   => $config['nginx_lua_module']
      }

      # Configure NGINX Conf for Lua
      # Important: MUST be in this order so ndk writes to the
      # nginx.conf before the lua module
      # ini_setting { 'Configure lua module in NGINX Conf':
      #   ensure            => present,
      #   path              => '/etc/nginx/nginx.conf',
      #   section           => '# MANAGED BY PUPPET',
      #   setting           => 'load_module',
      #   value             => '/etc/nginx/modules/ngx_http_lua_module.so;',
      #   key_val_separator => ' ',
      #   section_prefix    => '',
      #   section_suffix    => '',
      #   notify            => Service['nginx'],
      #   require           => Package['nginx-lua-module'],
      # }->
      # ini_setting { 'Configure http module in NGINX Conf':
      #   ensure            => present,
      #   path              => '/etc/nginx/nginx.conf',
      #   section           => '# MANAGED BY PUPPET',
      #   setting           => 'load_module',
      #   value             => '/etc/nginx/modules/ndk_http_module.so;',
      #   key_val_separator => ' ',
      #   section_prefix    => '',
      #   section_suffix    => '',
      #   notify            => Service['nginx'],
      #   require           => Package['nginx-lua-module'],
      # }

      # Install Signal Sciences Yum Repo
      file { 'signal-sciences-yum-repo':
        ensure  => file,
        path    => '/etc/yum.repos.d/sigsci.repo',
        content => $config['signal_science_yum_repo']
      }

      # Install Signal Sciences Agent
      package { 'signal-sciences-module':
        ensure  => installed,
        name    => $signal_sciences_agent,
        require => File['signal-sciences-yum-repo'],
      }

      # Configure Signal Sciences Agent
      $signal_sciences_agent_content = "accesskeyid = \"${access_key}\" \nsecretaccesskey = \"${secret_key}\""
      file { 'signal-sciences-agent-config':
        ensure  => file,
        path    => '/etc/sigsci/agent.conf',
        content => $signal_sciences_agent_content,
        require => Package['signal-sciences-module'],
      }

      service { 'signal-sciences-agent':
        ensure  => running,
        name    => $signal_sciences_agent,
        enable  => true,
        require => File['signal-sciences-agent-config']
      }

      # Install Signal Sciences NGINX Module
      package { 'signal-sciences-nginx-module':
        ensure  => installed,
        name    => $signal_sciences_nginx_module,
        require => File['signal-sciences-yum-repo'],
      }

      # ini_setting { 'configure signal sciences nginx module in NGINX conf':
      #   ensure            => present,
      #   path              => '/etc/nginx/nginx.conf',
      #   section           => 'include /etc/nginx/sites-enabled/*;',
      #   setting           => 'include',
      #   value             => '/opt/sigsci/nginx/sigsci.conf;',
      #   key_val_separator => ' ',
      #   section_prefix    => '',
      #   section_suffix    => '',
      #   notify            => Service['nginx'],
      #   require           => [
      #     Package['nginx-lua-module'],
      #     Package['signal-sciences-nginx-module'],
      #   ]
      # }
    }
  }
}
