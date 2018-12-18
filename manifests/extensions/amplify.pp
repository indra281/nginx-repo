# == Class: nginx::extensions::amplify
#

class nginx::extensions::amplify (
  $api_key = undef
)
{

  if ($api_key != undef) {
    $install_directory = '/tmp/install/amplify/'
    $install_full_path = "${install_directory}install.sh"

    # get amplify installer
    include wget

    file { $install_directory:
      ensure => directory,
    }->
    wget::fetch { 'amplify':
      source      => 'http://github.com/nginxinc/nginx-amplify-agent/raw/master/packages/install.sh',
      destination => $install_directory,
      timeout     => 0,
      verbose     => true,
    }->
    file { $install_full_path:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0777'
    }

    # install amplify
    exec { 'InstallAmplify':
      command     => "${install_full_path} -y",
      environment => "API_KEY=${api_key}",
      path        => '/usr/bin:/usr/sbin:/bin',
      onlyif      => 'sh service amplify-agent status | grep -w not-found',
      require     => [
        Package['wget'],
        File[$install_full_path],
      ],
      user        => 'root',
      group       => 'root'
    }->
    ini_setting { 'Configure Plus Status':
      ensure  => present,
      path    => '/etc/amplify-agent/agent.conf',
      section => 'nginx',
      setting => 'plus_status',
      value   => 'http://localhost:8080/status',
      notify  => Service['amplify-agent'],
    }

    service { 'amplify-agent':
      ensure     => running,
      enable     => true,
      hasrestart => false,
      hasstatus  => true,
    }
  }
}
