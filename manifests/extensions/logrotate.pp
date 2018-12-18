# == Class: nginx::extensions::logrotate

class nginx::extensions::logrotate (
  $log_rotate_interval_hours = 23,
  $cron_user = 'root'
)
{
    file { 'nginx-cron-directory':
      ensure => directory,
      path   => '/etc/nginx/cron',
      mode   => '0755'
    }

    # Create Log Rotation Script
    file { 'nginx-purge-logs.sh':
      ensure  => file,
      path    => '/etc/nginx/cron/nginx-purge-logs.sh',
      content => template('nginx/logrotate/nginx-purge-logs.sh.erb'),
      mode    => '0755',
      require => File['nginx-cron-directory'],
    }

    # Create Cron Job
    cron { 'nginx-log-purge':
      ensure  => present,
      command => '/etc/nginx/cron/nginx-purge-logs.sh',
      user    => $cron_user,
      hour    => $log_rotate_interval_hours,
      require => File['nginx-purge-logs.sh'],
    }
}
