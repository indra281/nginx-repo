# == Class: nginx::extensions::asgplugin
#

class nginx::extensions::asgplugin (
  $bucket_name = undef,
  $installer_name = undef,
  $asg_configs = undef,
)
{
  if ($asg_configs != undef) {
    $config_file_location = '/etc/nginx/aws.yaml'

    # get installer from S3
    file { '/tmp/install':
      ensure => directory,
    }->
    s3file { "/tmp/install/${installer_name}":
      ensure => 'latest',
      source => "${bucket_name}/${installer_name}",
    }

    # install asg plugin service
    package { 'nginx-asg-sync':
      ensure   => installed,
      source   => "/tmp/install/${installer_name}",
      provider => 'rpm',
      require  => S3file["/tmp/install/${installer_name}"]
    }

    # create config
    file { $config_file_location:
      ensure => file,
      notify => Service['nginx-asg-sync']
    }

    concat { $config_file_location:
      ensure         => present,
      backup         => false,
      ensure_newline => true,
      force          => true,
    }

    concat::fragment { 'asg-config-header':
      target  => $config_file_location,
      content => template('nginx/asgplugin/config-header.erb'),
      order   => '01'
    }

    concat::fragment { 'asg-config':
      target  => $config_file_location,
      content => template('nginx/asgplugin/config.erb'),
      order   => '02'
    }

    # start service
    service { 'nginx-asg-sync':
      ensure => running,
      enable => true,
    }
  }
}
