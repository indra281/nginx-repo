# == Class: nginx::extensions::certificate
# Copy certs from hiera to server
class nginx::extensions::certificate  (
  $certificates = undef
)
{
  file { '/etc/nginx/conf.d/default.conf':
    ensure => absent,
  }

  if ($certificates != undef) {
    file { '/etc/nginx/ssl':
      ensure => directory,
      mode   => '0700'
    }

    $certificates.each |$cert| {
      file { $cert['cert_path']:
        ensure  => file,
        mode    => '0600',
        content => $cert['cert_content'],
        require => File['/etc/nginx/ssl']
      }
    }
  }
}
