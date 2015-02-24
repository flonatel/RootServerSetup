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

  # Setup the network device(s)
  class { root_server_setup::network: }

  # Setup Firewall
  class { root_server_setup::firewall: }

  # Harden the OS and the SSH.
  # Please note to enable IPv6.
  
  class { 'os_hardening': 
    enable_ipv6 => "true",
  }

  class { 'root_server_setup::openssh': }
  ->
  class { 'ssh_hardening':
    server_options => {
      'AddressFamily' => "any",
      'AuthorizedKeysFile' => '/etc/ssh/authorized_keys/%u',
    },
  }
}
