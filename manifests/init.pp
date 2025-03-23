# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include jellyfin
class jellyfin (
  String $executable_dir,
  String $data_dir,
  String $cache_dir,
  String $config_dir,
  String $log_dir,
  String $system_user,
  String $system_platform,
  String $version,
  String $ffmpeg_version,
  String $ffmpeg_dir,
) {
  file { $executable_dir:
    ensure => 'directory',
    path   => $executable_dir,
    owner  => $system_user,
    # require => User[$system_user],
  }

  file { $ffmpeg_dir:
    ensure => 'directory',
    path   => $ffmpeg_dir,
    owner  => $system_user,
    # require => User[$system_user],
  }

  file { $data_dir:
    ensure => 'directory',
    path   => $data_dir,
    owner  => $system_user,
    # require => File[$executable_dir],
  }

  file { $cache_dir:
    ensure => 'directory',
    path   => $cache_dir,
    owner  => $system_user,
    # require => File[$executable_dir],
  }

  file { $config_dir:
    ensure => 'directory',
    path   => $config_dir,
    owner  => $system_user,
    # require => File[$executable_dir],
  }

  file { $log_dir:
    ensure => 'directory',
    path   => $log_dir,
    owner  => $system_user,
    # require => File[$executable_dir],
  }

  user { $system_user:
    ensure => 'present',
    name   => $system_user,
  }

  $jellyfin_archive_name = "jellyfin_${version}-${system_platform}.tar.gz"
  $jellyfin_download_url = "https://repo.jellyfin.org/files/server/linux/latest-stable/${system_platform}/${jellyfin_archive_name}"
  archive { "${executable_dir}/${jellyfin_archive_name}":
    ensure       => 'present',
    extract      => true,
    extract_path => $executable_dir,
    source       => $jellyfin_download_url,
    user         => $system_user,
    group        => $system_user,
    # require      => Archive[$ffmpeg_dir],
  }

  $ffmpeg_archive_name = "jellyfin-ffmpeg_${ffmpeg_version}_portable_linux64-gpl.tar.xz"
  $ffmpeg_download_url = "https://repo.jellyfin.org/files/ffmpeg/linux/latest-7.x/${system_platform}/${ffmpeg_archive_name}"
  archive { "${ffmpeg_dir}/${ffmpeg_archive_name}":
    ensure       => 'present',
    extract      => true,
    extract_path => $ffmpeg_dir,
    source       => $ffmpeg_download_url,
    user         => $system_user,
    group        => $system_user,
    require      => File[$ffmpeg_dir],
  }

  file { "${executable_dir}/start.sh":
    ensure  => 'file',
    owner   => $system_user,
    mode    => '0775',
    content => epp('jellyfin/server.sh.epp', {
        'executable_dir' => $executable_dir,
        'ffmpeg_dir'     => $ffmpeg_dir,
        'data_dir'       => $data_dir,
        'cache_dir'      => $cache_dir,
        'config_dir'     => $config_dir,
        'log_dir'        => $log_dir,
    }),
  }

  file { '/etc/systemd/system/jellyfin.service':
    ensure  => 'file',
    mode    => '0644',
    content => epp('jellyfin/jellyfin.service.epp', {
        'system_user' => $system_user,
    }),
  }

  service { 'jellyfin.service':
    ensure => 'running',
    name   => 'jellyfin.service',
    enable => true,
    # require => File['/etc/systemd/system/jellyfin.service'],
  }

  firewalld_port { 'Open port for jellyfin to the public':
    ensure   => present,
    zone     => 'public',
    port     => 8096,
    protocol => 'tcp',
  }

  # Make sure firewalld is running
  service { 'firewalld':
    ensure => running,
    enable => true,
    name   => 'firewalld',
  }
}
