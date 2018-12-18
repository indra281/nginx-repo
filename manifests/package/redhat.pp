# Class: nginx::package::redhat
#
# This module manages NGINX package installation on RedHat based systems
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
class nginx::package::redhat (
  $manage_repo    = true,
  $package_ensure = 'present',
  $package_name   = 'nginx',
  $package_source = 'nginx-stable',
) {

  # SELinux prevents NGINX from binding to ports
  # Set it to permissive
  class { 'selinux':
    mode => 'permissive',
    type => 'targeted'
  }->
  exec { 'setenforce 0':
    path   => '/usr/bin:/usr/sbin:/bin',
    user   => 'root',
    group  => 'root',
    onlyif => '/usr/bin/test ! -d /etc/nginx/conf.d',
  }

  #Install the CentOS-specific packages on that OS, otherwise assume it's a RHEL
  #clone and provide the Red Hat-specific package. This comes into play when not
  #on RHEL or CentOS and $manage_repo is set manually to 'true'.
  if $::operatingsystem == 'centos' {
    $_os = 'centos'
  } else {
    $_os = 'rhel'
  }

  if $manage_repo {
    case $package_source {
      'nginx', 'nginx-stable': {
        yumrepo { 'nginx-release':
          baseurl  => "http://nginx.org/packages/${_os}/${::operatingsystemmajrelease}/\$basearch/",
          descr    => 'nginx repo',
          enabled  => '1',
          gpgcheck => '1',
          priority => '1',
          gpgkey   => 'http://nginx.org/keys/nginx_signing.key',
          before   => Package['nginx'],
        }

        yumrepo { 'passenger':
          ensure => absent,
          before => Package['nginx'],
        }

      }
      'nginx-mainline': {
        yumrepo { 'nginx-release':
          baseurl  => "http://nginx.org/packages/mainline/${_os}/${::operatingsystemmajrelease}/\$basearch/",
          descr    => 'nginx repo',
          enabled  => '1',
          gpgcheck => '1',
          priority => '1',
          gpgkey   => 'http://nginx.org/keys/nginx_signing.key',
          before   => Package['nginx'],
        }

        yumrepo { 'passenger':
          ensure => absent,
          before => Package['nginx'],
        }

      }
      'passenger': {
        if ($::operatingsystem in ['RedHat', 'CentOS']) and ($::operatingsystemmajrelease in ['6', '7']) {
          yumrepo { 'passenger':
            baseurl       => "https://oss-binaries.phusionpassenger.com/yum/passenger/el/${::operatingsystemmajrelease}/\$basearch",
            descr         => 'passenger repo',
            enabled       => '1',
            gpgcheck      => '0',
            repo_gpgcheck => '1',
            priority      => '1',
            gpgkey        => 'https://packagecloud.io/gpg.key',
            before        => Package['nginx'],
          }

          yumrepo { 'nginx-release':
            ensure => absent,
            before => Package['nginx'],
          }

          package { 'passenger':
            ensure  => present,
            require => Yumrepo['passenger'],
          }

        } else {
          fail("${::operatingsystem} version ${::operatingsystemmajrelease} is unsupported with \$package_source 'passenger'")
        }
      }
      'nginx-plus': {
        yumrepo { 'nginx-release':
          baseurl       => "https://plus-pkgs.nginx.com/centos/${::operatingsystemmajrelease}/\$basearch/",
          descr         => 'nginx-plus repo',
          enabled       => '1',
          gpgcheck      => '0',
          priority      => '1',
          sslclientcert => '/etc/ssl/nginx/nginx-repo.crt',
          sslclientkey  => '/etc/ssl/nginx/nginx-repo.key',
          before        => Package['nginx'],
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

        yumrepo { 'passenger':
          ensure => absent,
        }
      }
      'passenger': {
        if ($::operatingsystem in ['RedHat', 'CentOS']) and ($::operatingsystemmajrelease in ['6', '7']) {
          yumrepo { 'passenger':
            baseurl       => "https://oss-binaries.phusionpassenger.com/yum/passenger/el/${::operatingsystemmajrelease}/\$basearch",
            descr         => 'passenger repo',
            enabled       => '1',
            gpgcheck      => '0',
            repo_gpgcheck => '1',
            priority      => '1',
            gpgkey        => 'https://packagecloud.io/gpg.key',
            before        => Package['nginx'],
          }

          yumrepo { 'nginx-release':
            ensure => absent,
          }

          package { 'passenger':
            ensure  => present,
            require => Yumrepo['passenger'],
          }

        } else {
          fail("${::operatingsystem} version ${::operatingsystemmajrelease} is unsupported with \$package_source 'passenger'")
        }
      }
      default: {
        fail("\$package_source must be 'nginx-stable', 'nginx-mainline', 'nginx-plus', or 'passenger'. It was set to '${package_source}'")
      }
    }
  }

  package { 'nginx':
    ensure => $package_ensure,
    name   => $package_name,
  }
}
