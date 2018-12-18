# Class: nginx::package::debian
#
# This module manages NGINX package installation on debian based systems
#
# Parameters:
#
# There are no default parameters for this class.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# This class file is not called directly
class nginx::package::debian (
    $manage_repo    = true,
    $package_name   = 'nginx',
    $package_source = 'nginx',
    $package_ensure = 'present'
  ) {

  $distro = downcase($::operatingsystem)

  package { 'nginx':
    ensure => $package_ensure,
    name   => $package_name,
  }

  if $manage_repo {
    include '::apt'
    Exec['apt_update'] -> Package['nginx']

    case $package_source {
      'nginx', 'nginx-stable': {
        apt::source { 'nginx':
          location => "http://nginx.org/packages/${distro}",
          repos    => 'nginx',
          key      => '573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62',
        }
      }
      'nginx-mainline': {
        apt::source { 'nginx':
          location => "http://nginx.org/packages/mainline/${distro}",
          repos    => 'nginx',
          key      => '573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62',
        }
      }
      'nginx-plus': {
        apt::source { 'nginx':
          location => "https://plus-pkgs.nginx.com/${distro}",
          repos    => 'nginx-plus',
          key      => '573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62',
        }
        exec { 'download 90nginx file':
        command => '/usr/bin/wget -q -O /etc/apt/apt.conf.d/90nginx https://cs.nginx.com/static/files/90nginx',
        creates => '/etc/apt/apt.conf.d/90nginx'
        }
        file { '/etc/ssl/nginx':
          ensure => directory,
          mode   => '0700',
          owner  => 'root',
          group  => 'root',
        }
        file { '/etc/ssl/nginx/nginx-repo.crt':
          ensure => present,
          mode   => '0700',
          owner  => 'root',
          group  => 'root',
          source => 'puppet:///modules/nginx/lic/nginx-repo.crt',
        }
        file { '/etc/ssl/nginx/nginx-repo.key':
          ensure => present,
          mode   => '0700',
          owner  => 'root',
          group  => 'root',
          source => 'puppet:///modules/nginx/lic/nginx-repo.key',
        }
      }
      'passenger': {
        apt::source { 'nginx':
          location => 'https://oss-binaries.phusionpassenger.com/apt/passenger',
          repos    => 'main',
          key      => '16378A33A6EF16762922526E561F9B9CAC40B2F7',
        }

        ensure_packages([ 'apt-transport-https', 'ca-certificates' ])

        Package['apt-transport-https','ca-certificates'] -> Apt::Source['nginx']

        package { 'passenger':
          ensure  => 'present',
          require => Exec['apt_update'],
        }

        if $package_name != 'nginx-extras' {
          warning('You must set $package_name to "nginx-extras" to enable Passenger')
        }
      }
      default: {
        fail("\$package_source must be 'nginx-stable', 'nginx-mainline' or 'passenger'. It was set to '${package_source}'")
      }
    }
  }
}
