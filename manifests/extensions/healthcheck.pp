# == Class: nginx::extensions::healthcheck
# DHI Implementation of NGINX Healthchecks

class nginx::extensions::healthcheck (
    $healthchecks = undef
)
{
  if ($healthchecks != undef) {
    file {'/etc/nginx/conf.d/healthcheck-match-status.conf':
      ensure => file,
    }

    concat {'/etc/nginx/conf.d/healthcheck-match-status.conf':
      ensure         => present,
      backup         => false,
      ensure_newline => true,
      force          => true,
    }

    $healthchecks.each |$healthcheck| {
      concat::fragment { $healthcheck['healthcheck_name']:
        target  => '/etc/nginx/conf.d/healthcheck-match-status.conf',
        content => template("nginx/healthchecks/${healthcheck['healthcheck_template']}"),
      }
    }
  }
}
