class root_server_setup::user(
  $username = 'dummyuser',
  $password = "*",
  $uid      = '7777',
  $gid      = '7777',
  $sshkeys  = "",
) {
  group { 'maintenace':
    ensure           => 'present',
    gid              => "$gid",
  }
  -> 
  user { "$username":
    ensure           => 'present',
    comment          => 'Maintenance user',
    gid              => "$gid",
    home             => "/home/$username",
    password         => "$password",
    shell            => '/bin/bash',
    uid              => "$uid",
    purge_ssh_keys   => "true",
  }
  ->
  file { "/home/$username":
    ensure           => 'directory',
    group            => "$gid",
    mode             => "0700",
    owner            => "$uid",
  }

  file { "/etc/ssh/authorized_keys":
    ensure           => 'directory',
    mode             => '0644',
    group            => '0',
    owner            => '0',
  }
  ->
  file { "/etc/ssh/authorized_keys/$username":
    ensure           => 'file',
    mode             => '0444',
    group            => '0',
    owner            => '0',
    content          => "$sshkeys",
  }
}  
