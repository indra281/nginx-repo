# == Class: nginx::extensions::waf

class nginx::extensions::waf (
  $config = undef
)
{
  if ($config != undef)
  {
    if ($::operatingsystem == 'centos')
    {
      # Install NGINX WAF Module
      package { 'nginx-waf-module':
        ensure => $config['nginx_waf_module_version'],
        name   => $config['nginx_waf_module']
      }

      file {'/etc/nginx/modsec/waf_ip_ban_list.data':
        ensure  => file,
        require => Package['nginx-waf-module'],
        notify  => Service['nginx']
      }

      file {'/etc/nginx/modsec/waf_user_agent_ban_list.data':
        ensure  => file,
        require => Package['nginx-waf-module'],
        notify  => Service['nginx']
      }

      concat {'/etc/nginx/modsec/waf_ip_ban_list.data':
        ensure         => present,
        backup         => false,
        ensure_newline => true,
        force          => true,
      }

      concat {'/etc/nginx/modsec/waf_user_agent_ban_list.data':
        ensure         => present,
        backup         => false,
        ensure_newline => true,
        force          => true,
      }

      $config['waf_ip_ban_list'].each |$banned_ip| {
        concat::fragment { $banned_ip:
          target  => '/etc/nginx/modsec/waf_ip_ban_list.data',
          content => $banned_ip,
        }
      }

      $config['waf_user_agent_ban_list'].each |$banned_agent| {
        concat::fragment { $banned_agent:
          target  => '/etc/nginx/modsec/waf_user_agent_ban_list.data',
          content => $banned_agent,
        }
      }

      file { 'modsecurity.conf':
        ensure  => file,
        content => template('nginx/waf/modsecurity-conf.erb'),
        path    => '/etc/nginx/modsec/modsecurity.conf',
        require => Package['nginx-waf-module'],
        notify  => Service['nginx']
      }

      file { 'crs-setup.conf':
        ensure  => file,
        source  => 'puppet:///modules/nginx/waf/crs-setup.conf',
        path    => '/etc/nginx/modsec/crs-setup.conf',
        require => Package['nginx-waf-module'],
        notify  => Service['nginx']
      }

      file { 'crs-rules':
        ensure  => directory,
        source  => 'puppet:///modules/nginx/waf/rules',
        path    => '/etc/nginx/modsec/rules',
        recurse => true,
        require => File['crs-setup.conf'],
        notify  => Service['nginx']
      }

      file { 'main.conf':
        ensure  => file,
        content => template('nginx/waf/main-conf.erb'),
        path    => '/etc/nginx/modsec/main.conf',
        require => [
            File['modsecurity.conf'],
            File['crs-setup.conf'],
            File['crs-rules'],
            File['/etc/nginx/modsec/waf_ip_ban_list.data'],
            File['/etc/nginx/modsec/waf_user_agent_ban_list.data']
          ],
        notify  => Service['nginx']
      }
    }
  }
}
