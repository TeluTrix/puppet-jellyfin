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

  $jellyfin_download_url = "https://repo.jellyfin.org/files/server/linux/latest-stable/${system_platform}/jellyfin_${version}-${system_platform}.tar.gz"

  archive { $executable_dir:
    ensure => 'present',
    source => $jellyfin_download_url,
    user   => $system_user,
    group  => $system_user,
    # require      => Archive[$ffmpeg_dir],
  }

  file { "${executable_dir}/current":
    ensure  => 'link',
    target  => "${executable_dir}/jellyfin_${version}",
    require => File[$executable_dir],
  }

  $ffmpeg_download_url = "https://repo.jellyfin.org/files/ffmpeg/linux/latest-7.x/${system_platform}/jellyfin-ffmpeg_${ffmpeg_version}_portable_linux64-gpl.tar.xz"
  archive { $ffmpeg_dir:
    ensure  => 'present',
    source  => $ffmpeg_download_url,
    user    => $system_user,
    group   => $system_user,
    require => File[$ffmpeg_dir],
  }

  file { "${executable_dir}/start.sh":
    ensure  => 'file',
    owner   => $system_user,
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
        'executable_dir' => $executable_dir,
        'ffmpeg_dir'     => $ffmpeg_dir,
        'data_dir'       => $data_dir,
        'cache_dir'      => $cache_dir,
        'config_dir'     => $config_dir,
        'log_dir'        => $log_dir,
    }),
  }

  service { 'jellyfin.service':
    ensure => 'running',
    name   => 'jellyfin.service',
    enable => true,
    # require => File['/etc/systemd/system/jellyfin.service'],
  }
}
