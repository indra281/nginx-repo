# == Class: nginx::extensions::cloudwatch
#

class nginx::extensions::cloudwatch (
  $brand_name = undef,
  $stub_stats_url = undef
)
{
  include wget
  include stdlib

  $list_of_templates = [
    'CloudWatchClient.pm',
    'mon-put-instance-data.pl',
    'nginx-aws-logger.py',
    'settings.py'
  ]

  file { "/etc/${brand_name}/":
    ensure => directory
  }

  $list_of_templates.each |$value| {
    file { "/etc/${brand_name}/${value}":
      ensure  => file,
      content => template("nginx/cloudwatch/${value}.erb"),
      mode    => '0755'
    }
  }

  file { '/etc/cron.d/nginx-cloudwatch':
    ensure  => file,
    content => template('nginx/cron.d/nginx-cloudwatch.erb')
  }

  $list_of_packages = [
    'perl-Switch',
    'perl-DateTime',
    'perl-Sys-Syslog',
    'perl-LWP-Protocol-https',
    'perl-Digest-SHA'
  ]

  $list_of_packages.each |$package| {
    package { $package:
      ensure => 'installed'
    }
  }
}
