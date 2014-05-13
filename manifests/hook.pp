define managedmac::hook ($enable, $scripts) {

  # We only handle names login and logout. There are no other types of
  # hooks and we only ever want one resource for each.
  case $name {
    'login':   { $type = 'login' }
    'logout':  { $type = 'logout' }
    default:   { fail("Parameter Error: invalid :name, ${name}. Must be one of
      'login' OR 'logout'.") }
  }

  validate_bool ($enable)

  $path        = ['/usr/bin', '/bin', '/usr/sbin', '/sbin', '/usr/local/bin',]
  $masterhooks = '/etc/masterhooks'
  $hook        = "${masterhooks}/${type}hook.rb"
  $label       = join([capitalize($type), 'Hook'], '')
  $prefs       = '/private/var/root/Library/Preferences/com.apple.loginwindow'

  if $enable {

    validate_absolute_path ($scripts)

    file { $scripts:
      ensure => directory,
      owner  => 'root',
      group  => 'wheel',
      mode   => '0750',
    }

    # This is a conditional resource. We only define it if it's
    # not being defined anywhere else. We do this so that loginhooks and
    # logouthooks don't conflict of over who creates the masterhooks dir.
    if ! defined_with_params(File[$masterhooks], {'ensure' => 'directory' }) {
      file { $masterhooks:
        ensure => directory,
        owner  => 'root',
        group  => 'wheel',
        mode   => '0750',
      }
    }

    file { $hook:
      require => File["${masterhooks}"],
      ensure  => file,
      owner   => 'root',
      group   => 'wheel',
      mode    => '0750',
      content => template('managedmac/masterhook_template.erb')
    }

    exec { "activate_${type}_hook":
      path    => $path,
      command => "defaults write ${prefs} ${label} ${hook}",
      unless  => "defaults read  ${prefs} ${label} | grep ${hook}",
    }

  } else {

    file { $hook: ensure => absent }

    exec { "deactivate_${type}_hook":
      path    => $path,
      command => "defaults delete ${prefs} ${label}",
      onlyif  => "defaults read   ${prefs} ${label} | grep ${hook}",
    }

  }

}