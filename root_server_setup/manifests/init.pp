class root_server_setup(
  $username = 'dummyuser',
  $password = "*",
  $uid      = '7777',
  $gid      = '7777',
  $sshkeys  = "",
) {

  # Set up the one and only user with public key authentication.

  class { root_server_setup::user:
    username => $username,
    password => $password,
    uid      => $uid,
    gid      => $gid,
    sshkeys  => $sshkeys
  }

  # Harden the OS and the SSH.
  # Please note to enable IPv6.
  
  class { 'os_hardening': 
    enable_ipv6 => "true",
  }
  class { 'ssh_hardening':
    server_options => {
      'AddressFamily' => "any",
      'AuthorizedKeysFile' => '/etc/ssh/authorized_keys/%u',
    },
  }

  # Setup Firewall
  
  # iptables purge
  resources { "firewall":
    purge   => true
  }
  Firewall {
    before  => Class['root_server_setup::firewall_post'],
    require => Class['root_server_setup::firewall_pre'],
  }
  class { ['root_server_setup::firewall_pre',
   	   'root_server_setup::firewall_post']: }
}
