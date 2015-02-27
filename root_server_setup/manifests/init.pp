class root_server_setup(
  $username = 'dummyuser',
  $password = "*",
  $uid      = '7777',
  $gid      = '7777',
  $sshkeys  = "",

  $nw_device   = "eth0",
  $nw_ipaddr1  = "192.168.122.2",
  $nw_netmask1   = "255.255.255.0",
  $nw_network1   = "192.168.122.0",
  $nw_gateway1   = "192.168.122.1",
  $nw_broadcast1 = "192.268.122.255",
  $nw_dns_nameservers = "",
  $nw_search     = ""

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
  class { root_server_setup::network:
    device    => $nw_device,
    ipaddr1   => $nw_ipaddr1,
    netmask1  => $nw_netmask1,
    network1  => $nw_network1,
    gateway1  => $nw_gateway1,
    broadcast1 => $nw_broadcast1,
    dns_nameservers => $nw_dns_nameservers,
    dns_search => $nw_search,
  }

  # Setup Firewall
  class { root_server_setup::firewall: }

  # Harden the OS and the SSH.
  # Please note to enable IPv6.

  class { 'root_server_setup::powerdns': }
  
  class { 'os_hardening': 
    enable_ipv6 => "true",
  }

  class { 'root_server_setup::openssh': }
  ->
  class { 'ssh_hardening':
    server_options => {
      'AddressFamily' => "any",
      'AuthorizedKeysFile' => '/etc/ssh/authorized_keys/%u',
      'ListenAddress' => ['0.0.0.0', '2001:1b60:2:ff36:1::101'],
    },
  }
}
