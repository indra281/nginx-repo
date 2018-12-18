# == Class: nginx::extensions::maintpage
#

class nginx::extensions::maintpage (
  $bucket_name = undef,
  $sites = undef
)
{
  if ($sites != undef) {
    $site_root = '/usr/share/nginx/html'

    $sites.each |$maint_site| {
      $maint_dir_name = "${maint_site['site_name']}-maint-www"
      $maint_dir_path = "${site_root}/${maint_dir_name}"

      exec { "GetMaintPageFiles-${maint_dir_name}":
        command => "aws s3 cp s3://${bucket_name}/${maint_dir_name} ${maint_dir_path} --recursive",
        path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
        unless  => "find ${maint_dir_path} -type d -empty -exec exit {} 0 \;"
      }
    }
  }
}
